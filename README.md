# Database-Exploration

This repository contains code to explore glacier databases and make intersection between them.

Supported databases:
- [Randolph Glacier Inventory (RGI)](https://www.glims.org/RGI/)
- [Theia annual speed product](https://www.theia-land.fr/product/vitesse-decoulement-des-glaciers-2017-2018/) from Millan et al. (2022)
- Surface flow velocity: datacubes of speed over time which are available through internal resources at IGE

# Data folder

All data are stored in the `data/` folder.

## RGI

Data can be downloaded at https://daacdata.apps.nsidc.org/pub/DATASETS/nsidc0770_rgi_v7/ which requires to create an account (free). The regional files should be unzipped and placed in the `data/RGI/` folder according to the following organization:

```
data/RGI
|-- RGI2000-v7.0-G-01_alaska
|   |-- README.md
|   |-- RGI2000-v7.0-G-01_alaska-attributes.csv
|   |-- RGI2000-v7.0-G-01_alaska-attributes_metadata.json
|   |-- RGI2000-v7.0-G-01_alaska.cpg
|   |-- RGI2000-v7.0-G-01_alaska.dbf
|   |-- RGI2000-v7.0-G-01_alaska-hypsometry.csv
|   |-- RGI2000-v7.0-G-01_alaska.prj
|   |-- RGI2000-v7.0-G-01_alaska-rgi6_links.csv
|   |-- RGI2000-v7.0-G-01_alaska.shp
|   |-- RGI2000-v7.0-G-01_alaska.shx
|   |-- RGI2000-v7.0-G-01_alaska-submission_info.csv
|   `-- RGI2000-v7.0-G-01_alaska-submission_info_metadata.json
|-- RGI2000-v7.0-G-02_western_canada_usa
|   |-- README.md
|   |-- RGI2000-v7.0-G-02_western_canada_usa-attributes.csv
|   |-- RGI2000-v7.0-G-02_western_canada_usa-attributes_metadata.json
|   |-- RGI2000-v7.0-G-02_western_canada_usa.cpg
|   |-- RGI2000-v7.0-G-02_western_canada_usa.dbf
|   |-- RGI2000-v7.0-G-02_western_canada_usa-hypsometry.csv
|   |-- RGI2000-v7.0-G-02_western_canada_usa.prj
|   |-- RGI2000-v7.0-G-02_western_canada_usa-rgi6_links.csv
|   |-- RGI2000-v7.0-G-02_western_canada_usa.shp
|   |-- RGI2000-v7.0-G-02_western_canada_usa.shx
|   |-- RGI2000-v7.0-G-02_western_canada_usa-submission_info.csv
|   `-- RGI2000-v7.0-G-02_western_canada_usa-submission_info_metadata.json
|-- RGI2000-v7.0-G-03_arctic_canada_north
|   |-- README.md
|   |-- RGI2000-v7.0-G-03_arctic_canada_north-attributes.csv
|   |-- RGI2000-v7.0-G-03_arctic_canada_north-attributes_metadata.json
|   |-- RGI2000-v7.0-G-03_arctic_canada_north.cpg
|   |-- RGI2000-v7.0-G-03_arctic_canada_north.dbf
|   |-- RGI2000-v7.0-G-03_arctic_canada_north-hypsometry.csv
|   |-- RGI2000-v7.0-G-03_arctic_canada_north.prj
|   |-- RGI2000-v7.0-G-03_arctic_canada_north-rgi6_links.csv
|   |-- RGI2000-v7.0-G-03_arctic_canada_north.shp
|   |-- RGI2000-v7.0-G-03_arctic_canada_north.shx
|   |-- RGI2000-v7.0-G-03_arctic_canada_north-submission_info.csv
|   `-- RGI2000-v7.0-G-03_arctic_canada_north-submission_info_metadata.json
...
```

## Theia annual speed product

Data can be downloaded from the [SEDOO website](https://www.sedoo.fr/theia-publication-products/?uuid=55acbdd5-3982-4eac-89b2-46703557938c) and they should be organized as follows in `data/Theia_annual_speed/`:

```
data/Theia_annual_speed
|-- thickness
|   |-- RGI-1.zip
|   |-- RGI-2.zip
|   `-- RGI-3.zip
`-- velocity
    |-- RGI-1.zip
    |-- RGI-2.zip
    `-- RGI-3.zip
```

## Surface flow velocity

If you have access to the IGE's resources, the `data/surface_flow_velocity/` folder can be copied using `rsync`. This is done automatically by the scripts provided that you have enabled SSH public key authentication.
