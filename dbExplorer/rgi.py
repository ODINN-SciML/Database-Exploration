import geopandas as gpd
import rasterio
import rasterio.plot
from rasterio.windows import from_bounds
from rasterio.mask import mask
import numpy as np
from pyproj import Transformer
from tqdm import tqdm
import os.path as osp
import json
import glob
from zipfile import ZipFile

import warnings
warnings.filterwarnings('ignore', module='pyproj')

import dbExplorer


def hasValidSpeed(glacier, tiff):
    pos = np.array(glacier.geometry.get_coordinates())
    xmin = pos[:,0].min()
    xmax = pos[:,0].max()
    ymin = pos[:,1].min()
    ymax = pos[:,1].max()
    dx=xmax-xmin
    dy=ymax-ymin

    left = xmin-0.05*dx
    bottom = ymin-0.05*dy
    right = xmax+0.05*dx
    top = ymax+0.05*dy
    wd = from_bounds(left, bottom, right, top, tiff.transform)
    rst = tiff.read(1, window=wd)

    return (1-np.isnan(rst)).sum()

def mapToEpsg(glacier, epsgNum):
    glacierMapped = glacier.to_crs("epsg:"+str(epsgNum))

    cenlon, cenlat = np.array(glacierMapped.geometry.centroid.get_coordinates())[0]
    glacierMapped.cenlon = cenlon
    glacierMapped.cenlat = cenlat

    transformer = Transformer.from_crs("epsg:4326", "epsg:"+str(epsgNum)) # epsg:4326 is WGS 84
    d = transformer.transform(glacier.termlat, glacier.termlon)
    glacierMapped.termlon = d[0][0]
    glacierMapped.termlat = d[1][0]
    return glacierMapped

def getSpeed(tiff, glacier):
    out, _ = mask(tiff, glacier.geometry, invert=False, crop=True, filled=False)
    valInside = out[~out.mask].data
    valInside = valInside[~np.isnan(valInside)]
    return valInside


areaIdToName = {1: 'alaska', 2: 'western_canada_usa', 3: 'arctic_canada_north', 4: 'arctic_canada_south',
                5: 'greenland_periphery', 6: 'iceland', 7: 'svalbard_jan_mayen', 8: 'scandinavia',
                9: 'russian_arctic', 10: 'north_asia', 11: 'central_europe', 12: 'caucasus_middle_east',
                13: 'central_asia', 14: 'south_asia_west', 15: 'south_asia_east', 16: 'low_latitudes',
                17: 'southern_andes', 18: 'new_zealand', 19: 'subantarctic_antarctic_islands'}

def rgiShpFile(areaId):
    areaName = areaIdToName[areaId]
    return f'{dbExplorer.absPathData}/RGI/RGI2000-v7.0-G-{areaId:02d}_{areaName}/RGI2000-v7.0-G-{areaId:02d}_{areaName}.shp'

def tiffFile(areaId):
    folder = f"{dbExplorer.absPathData}/Theia_annual_speed/velocity/RGI-{areaId}"
    if not osp.isdir(folder):
        if osp.exists(folder+'.zip'):
            print("Folder doesn't exist but zip was found. Extracting it...")
            with ZipFile(folder+'.zip', 'r') as zipFile:
                zipFile.extractall(osp.join(folder, '..'))
        else:
            raise FileNotFoundError(f"File {folder}.zip wasn't found")
    f = glob.glob(f"{folder}/V_RGI-*.tif")
    assert len(f)>0, "Tiff files don't seem to exist"
    if len(f)>1:
        return '.'.join(f[0].split('.')[:-2])+'.*_'+f[0].split('_')[-1]
    else:
        return f[0]

class Region:
    def __init__(self, areaId):
        self.areaId = areaId
        self.areaName = areaIdToName[areaId]
        self.shpFileName = rgiShpFile(self.areaId)
        self.tiffFileName = tiffFile(self.areaId)
        self.gdf = gpd.read_file(self.shpFileName)
        self.glaciersOfInterest = self.gdf.copy()
        if '*' in self.tiffFileName:
            filenames = sorted(glob.glob(self.tiffFileName))
        else:
            filenames = [self.tiffFileName]
        self.tiffs = []
        for fn in filenames:
            self.tiffs.append(rasterio.open(fn))
        self.associatedTiffNb = None

    def filterGlaciersOutsideTiff(self):
        associatedTiffNb = self.getAssociatedTiffDict()
        glaciersToRemove = []
        for gid in tqdm(self.glaciersOfInterest.rgi_id):
            glacierWgs84 = self.glaciersOfInterest.loc[self.glaciersOfInterest.rgi_id==gid]
            tiffNb = associatedTiffNb[glacierWgs84['rgi_id'].item()]
            if tiffNb is None:
                glaciersToRemove.append(gid)
                continue
        print(f"{len(glaciersToRemove)=}")
        for gid in glaciersToRemove:
            self.glaciersOfInterest = self.glaciersOfInterest.drop(self.glaciersOfInterest[self.glaciersOfInterest.rgi_id==gid].index)

    def filterArea(self, thresArea=1):
        self.glaciersOfInterest = self.glaciersOfInterest[self.glaciersOfInterest['area_km2']>thresArea]

    def getAssociatedTiffDict(self):
        if self.associatedTiffNb is not None: return self.associatedTiffNb
        if len(self.tiffs)>1:
            fileName_associatedTiffNb = f"{dbExplorer.absPathData}/Theia_annual_speed/associatedTiffNb_{self.areaName}.json"
            if osp.exists(fileName_associatedTiffNb):
                with open(fileName_associatedTiffNb, "r") as infile:
                    self.associatedTiffNb = json.load(infile)
            else:
                self.associatedTiffNb = {}
                for rgi_id in tqdm(self.gdf['rgi_id']):
                    glacier = self.gdf.loc[self.gdf.rgi_id==rgi_id]
                    self.associatedTiffNb[rgi_id] = self.findCorrespondingTiff(glacier)
                for k in self.associatedTiffNb:
                    if isinstance(self.associatedTiffNb[k], np.int64):
                        self.associatedTiffNb[k] = int(self.associatedTiffNb[k])
                with open(fileName_associatedTiffNb, "w") as outfile:
                    json.dump(self.associatedTiffNb, outfile)
        else:
            self.associatedTiffNb = {rgi_id: 0 for rgi_id in self.gdf['rgi_id']}
        return self.associatedTiffNb

    def findCorrespondingTiff(self, glacierWgs84):
        associatedTiffNb = []
        for e,tiff in enumerate(self.tiffs):
            glacier = mapToEpsg(glacierWgs84, tiff.crs.to_string().split(':')[1])
            x,y=np.array(glacier.geometry.centroid.get_coordinates())[0]
            bndx = (tiff.bounds.left, tiff.bounds.right)
            if bndx[0]>bndx[1]:
                bndx = bndx[::-1]
            bndy = (tiff.bounds.bottom, tiff.bounds.top)
            if bndy[0]>bndy[1]:
                bndy = bndy[::-1]
            if bndx[0]<x<bndx[1] and bndy[0]<y<bndy[1]:
                associatedTiffNb.append(e)
        if len(associatedTiffNb)==0:
            warnings.warn(f"Glacier {glacier['glac_name'].to_string()} with RGI ID {glacier['rgi_id'].to_string()} was not found in tiffs")
            return None
        if len(associatedTiffNb)>1:
            nbNonNanVoxels = []
            for e in associatedTiffNb:
                nbNonNanVoxels.append( hasValidSpeed(glacier, self.tiffs[e]) )
            valids = [e for i,e in enumerate(associatedTiffNb) if nbNonNanVoxels[i]>0]
            nbValid = len(valids)
            if nbValid==0:
                warnings.warn(f"Expected to find glacier {glacier['glac_name'].item()} with RGI ID {glacier['rgi_id'].item()} with non NaNs velocities in at least one tiff file but none of the files match")
                return None
            if nbValid>1:
                warnings.warn(f"Expected to find glacier {glacier['glac_name'].item()} with RGI ID {glacier['rgi_id'].item()} with non NaNs velocities in exactly one tiff file but {nbValid} files match. The one with the most non NaNs velocities is selected")
            return associatedTiffNb[np.argmax(nbNonNanVoxels)]
        else:
            associatedTiffNb = associatedTiffNb[0]
        return associatedTiffNb

    def getGlacier(self, gid):
        associatedTiffNb = self.getAssociatedTiffDict()
        glacierWgs84 = self.gdf.loc[self.gdf.rgi_id==gid]
        tiff = self.tiffs[associatedTiffNb[glacierWgs84['rgi_id'].item()]]
        epsgTiff = tiff.crs.to_string().split(':')[1]
        glacier = mapToEpsg(glacierWgs84, epsgTiff)
        return glacier

    def getSpeed(self, gid):
        associatedTiffNb = self.getAssociatedTiffDict()
        glacierWgs84 = self.gdf.loc[self.gdf.rgi_id==gid]
        tiff = self.tiffs[associatedTiffNb[glacierWgs84['rgi_id'].item()]]
        epsgTiff = tiff.crs.to_string().split(':')[1]
        glacier = mapToEpsg(glacierWgs84, epsgTiff)
        return getSpeed(tiff, glacier)

    def getGlacierInBox(self, leftLon, rightLon, topLat, bottomLat, useFiltered=False):
        rgi_ids = self.glaciersOfInterest.rgi_id if useFiltered else self.gdf.rgi_id
        glaciersInBox = []
        for gid in tqdm(rgi_ids):
            glacierWgs84 = self.gdf.loc[self.gdf.rgi_id==gid]
            extremePts = np.array(glacierWgs84.geometry.get_coordinates())
            for p in extremePts:
                if bottomLat<=p[1]<=topLat and leftLon<=p[0]<=rightLon:
                    glaciersInBox.append(glacierWgs84)
                    break
        return glaciersInBox
