# vtkToolbox for MATLAB

## Overview

vtkToolbox is a MEX interface to the VTK library. It provides functions to read and write VTK files and to apply VTK filters to VTK datasets. Currently, two types of datasets are supported: vtkPolyData and vtkUnstructuredGrid (both represented as vtkPointSet).
The toolbox is based on two functions for converting a vtkPointSet into a MATLAB struct and vice versa: vtkToStruct() and structToVtk().

#### Format of the MATLAB struct
The following format is used to represent a VTK dataset as a MATLAB struct:
```
myStruct.points:    [numPoints x numDim double/single/(u)intN], numDim <= 3
myStruct.cells:     [numCells x maxNumPointsPerCell int32]
myStruct.cellTypes: [numCells x 1 uint8] (see https://vtk.org/doc/nightly/html/vtkCellType_8h_source.html)
myStruct.pointData: [1 x 1 struct of point data arrays] (optional)
myStruct.cellData:  [1 x 1 struct of cell data arrays]  (optional)
myStruct.fieldData: [1 x 1 struct of field data arrays] (optional)
```

#### File input/output
The functions vtkRead() and vtkWrite() can be used to read and write various types of files supported by the VTK library.

#### Filters
The general procedure used by filters in the toolbox is:
* A MATLAB struct is passed to the MEX function and converted into a vtkPointSet using structToVtk().
* Desired VTK filters are applied to the vtkPointSet.
* The vtkPointSet is converted back to a MATLAB struct using vtkToStruct() and returned by the MEX function.

## Building the MEX functions

Before you can use the toolbox, you first have to compile the MEX functions for your platform:
* Install VTK (either using a package manager or from source – see https://vtk.org/Wiki/VTK/Configure_and_Build)
* Compile the MEX functions using CMake. In the folder "vtkToolbox", run:
    ```
    mkdir build
    cd build
    cmake ..
    make
    ```

## Adding new functions

The functionality of the toolbox can easily be extended by creating and compiling new functions:
* Duplicate the folder vtkTEMPLATE and replace "TEMPLATE" in file names and the cxx file.
* Adapt the cxx file by parsing the needed inputs and adding the desired operation(s) or filter(s) to the section "Apply operations to pointSet".
* Rerun CMake after adjusting "CMakeLists.txt" as follows:
    * Add a new line with all C++ source files of your MEX function to the section "Build MEX functions".
    * You might have to add more VTK components under the section "Set up VTK dependency".

* Duplicate MATLAB/vtkTEMPLATE.m and adapt it accordingly. This script is only needed for providing a function help and a function hint.

## License

All source code is subject to the terms of the Mozilla Public License, v. 2.0.  
Copyright 2020 Steffen Schuler, Karlsruhe Institute of Technology.

## Contact

Steffen Schuler  
Institute of Biomedical Engineering  
Karlsruhe Institute of Technology  
www.ibt.kit.edu