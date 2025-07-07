@echo off
uv --quiet tool run --from visidata --with ^
    h5py,lxml,numpy,openpyxl,pandas,pyarrow,pyyaml vd %*
