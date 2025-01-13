import numpy as np
import netCDF4
from osgeo import osr
from tqdm import tqdm
import rioxarray
import rasterio
import tempfile
import glob
import os
import os.path as osp
import subprocess
import socket
from itertools import product

import warnings
warnings.filterwarnings('ignore', module='rasterio')

import dbExplorer

validYears = {'new_zealand': [2017, 2018], 'alps': [2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022]}

def getServerFiles(area, period, user, year=None, copyLocal=False):
    assert area.lower() in validYears.keys()
    ret = []
    if year is None: year = validYears[area.lower()]
    elif not isinstance(year, list): year = [year]
    if not isinstance(period, list): period = [period]
    fileYears = []
    filePeriods = []
    for y, p in product(year, period):
        assert y in validYears[area.lower()], f"Year {y} is not in the list of valid years {validYears[area.lower()]}"
        path = f'surface_flow_velocity/{area.upper()}/SENTINEL-2/{y}/{p}d/MOSAIC/cubes/'
        srcpath = f"/summer/ice_speed/{path}"
        if copyLocal:
            locpath = osp.join(dbExplorer.absPathData, path)
            if not osp.isdir(locpath) or len(glob.glob(locpath+'/*'))<=1:
                print("Syncing folder")
                os.makedirs(locpath, exist_ok=True)
                if 'bigfoot' in socket.gethostname():
                    subprocess.call(["rsync", "-avxHO", "--no-perms", srcpath, locpath])
                else:
                    subprocess.call(["rsync", "-avxHO", "--no-perms", f"{user}@cargo.univ-grenoble-alpes.fr:{srcpath}", locpath])
                print("Syncing done")
            tmp = glob.glob(locpath+'/*')
        else:
            tmp = glob.glob(srcpath+'/*')
        ret += tmp
        fileYears += [y]*len(tmp)
        filePeriods += [p]*len(tmp)
    return ret, fileYears, filePeriods

class DataCube:
    def __init__(self, filePath, mapping=None):
        self.filePath = filePath
        self.fnetcdf = netCDF4.Dataset(self.filePath, 'r') # netCDF is more efficient if we just need to retrieve the bounds
        self.mapping = mapping or self.fnetcdf['mapping'].getncattr("spatial_ref")
        self.date1 = self.fnetcdf['date1'][:].tolist()
        self.date2 = self.fnetcdf['date2'][:].tolist()

        p1 = osr.SpatialReference()
        p1.ImportFromEPSG(4326)
        p2 = osr.SpatialReference()
        p2.ImportFromWkt(self.mapping)

        self.transformLocToWgs = osr.CoordinateTransformation(p2, p1)
        self.bottomlat, self.leftlon, _ = (self.transformLocToWgs.TransformPoint(np.min(self.fnetcdf['x'][:]).item(), np.min(self.fnetcdf['y'][:]).item()))
        self.toplat, self.rightlon, _ = (self.transformLocToWgs.TransformPoint(np.max(self.fnetcdf['x'][:]).item(), np.max(self.fnetcdf['y'][:]).item()))

    def readAsTiff(self, drop_vars=[]):
        self.rds = rioxarray.open_rasterio(self.filePath)
        if isinstance(self.rds, list): # Datacube corresponds to raw velocities
            tmp = self.rds[0]
            self.x = tmp.x.to_numpy()
            self.y = tmp.y.to_numpy()

            ret = self.transformLocToWgs.TransformPoints(np.stack([tmp.x,tmp.y]).T)
            self.Ywgs, self.Xwgs, _ = np.array(ret).T
            tmp['x'] = self.Xwgs
            tmp['y'] = self.Ywgs

            self.tiffs = {}
            for bandId in tqdm(range(len(tmp.band))):
                tmpName = tempfile.NamedTemporaryFile().name+".tif"
                tmp.isel(band=bandId).rio.to_raster(tmpName)
                julianTime = self.date1[bandId]
                self.tiffs[julianTime] = rasterio.open(tmpName)

        else: # Datacube corresponds to interpolated velocities
            tmp = self.rds
            self.x = tmp.x.to_numpy()
            self.y = tmp.y.to_numpy()

            ret = self.transformLocToWgs.TransformPoints(np.stack([tmp.x,tmp.y]).T)
            self.Ywgs, self.Xwgs, _ = np.array(ret).T
            tmp['x'] = self.Xwgs
            tmp['y'] = self.Ywgs

            self.tiffs = {}
            for e in tqdm(range(len(tmp.mid_date))):
                tmpName = tempfile.NamedTemporaryFile().name+".tif"
                tmp.isel(mid_date=e).drop_vars(drop_vars).rio.to_raster(tmpName)
                julianTime = self.date1[e]
                self.tiffs[julianTime] = rasterio.open(tmpName)

    def getSpeeds(self):
        return self.fnetcdf['vx'], self.fnetcdf['vy']

class Glacier:
    def __init__(self, glacier, files, sortValues=None):
        # glacier: glacier instance from netCDF
        self.glacier = glacier
        self.files = files
        self.dcContainingGlacier = None
        self.sortedIndex = np.argsort(sortValues) if sortValues is not None else range(len(self.files))
    def getDataCubes(self, mapping=None, drop_vars=[]):
        if self.dcContainingGlacier is not None:
            return self.dcContainingGlacier
        self.dcContainingGlacier = []
        extremePts = np.array(self.glacier.geometry.get_coordinates())
        for idx in tqdm(reversed(self.sortedIndex)):
            f = self.files[idx]
            dc = DataCube(f, mapping=mapping)
            for p in extremePts:
                if dc.bottomlat<=p[1]<=dc.toplat and dc.leftlon<=p[0]<=dc.rightlon:
                    self.dcContainingGlacier.append(dc)
                    break
        for dc in self.dcContainingGlacier:
            dc.readAsTiff(drop_vars=drop_vars)
        return self.dcContainingGlacier
