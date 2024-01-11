____________________________________________________________________________

                                  k-Wave

                    A MATLAB toolbox for the time-domain 
                     simulation of acoustic wave fields
____________________________________________________________________________

VERSION INFORMATION
____________________________________________________________________________

Version 1.3, Released 28th February 2020
Written by Bradley Treeby, Ben Cox, and Jiri Jaros
See individual files for complete list of authors

Please report bugs and suggestions on http://www.k-wave.org/forum
The toolbox may be downloaded from http://www.k-wave.org/download.php

NOTE: The photoacoustic reconstruction functions kspaceLineRecon and 
kspacePlaneRecon (all toolbox versions) do not work with R2012b.
____________________________________________________________________________

PRODUCT OVERVIEW
____________________________________________________________________________

k-Wave is an open source MATLAB toolbox designed for the time-domain 
simulation of propagating acoustic waves in 1D, 2D, or 3D [1]. The toolbox
has a wide range of functionality, but at its heart is an advanced numerical
model that can account for both linear and nonlinear wave propagation, an 
arbitrary distribution of heterogeneous material parameters, and power law 
acoustic absorption.

The numerical model is based on the solution of three coupled first-order 
partial differential equations which are equivalent to a generalised form 
of the Westervelt equation [2]. The equations are solved using a k-space 
pseudospectral method, where spatial gradients are calculated using a 
Fourier collocation scheme, and temporal gradients are calculated using a
k-space corrected finite-difference scheme. The temporal scheme is exact in
the limit of linear wave propagation in a homogeneous and lossless medium, 
and significantly reduces numerical dispersion in the more general case.

Power law acoustic absorption is accounted for using a linear integro-
differential operator based on the fractional Laplacian [3]. A split-field 
perfectly matched layer (PML) is used to absorb the waves at the edges of 
the computational domain. The main advantage of the numerical model used in 
k-Wave compared to models based on finite-difference time domain (FDTD) 
schemes is that fewer spatial and temporal grid points are needed for 
accurate simulations. This means the models run faster and use less memory. 
A detailed description of the model is given in the k-Wave User Manual and 
the references below.

[1] B. E. Treeby and B. T. Cox, "k-Wave: MATLAB toolbox for the simulation 
and reconstruction of photoacoustic wave-fields," J. Biomed. Opt., vol. 15,
no. 2, p. 021314, 2010. 
[2] B. E. Treeby, J. Jaros, A. P. Rendell, and B. T. Cox, "Modeling 
nonlinear ultrasound propagation in heterogeneous media with power law 
absorption using a k-space pseudospectral method," J. Acoust. Soc. Am., 
vol. 131, no. 6, pp. 4324-4336, 2012.
[3] B. E. Treeby and B. T. Cox, "Modeling power law absorption and 
dispersion for acoustic propagation using the fractional Laplacian," J. 
Acoust. Soc. Am., vol. 127, no. 5, pp. 2741-2748, 2010.
____________________________________________________________________________

INSTALLATION INSTRUCTIONS
____________________________________________________________________________

The k-Wave toolbox is installed by adding the root k-Wave folder to the 
MATLAB path. This can be done using the "Set Path" dialog box which is 
accessed by typing "pathtool" at the MATLAB command line. This dialog box 
can also be accessed using the "Set Path" button on the ribbon bar. Once the
dialog box is open, the toolbox is installed by clicking "Add Folder", 
selecting the k-Wave toolbox folder, and clicking "save". The toolbox can be
uninstalled in the same fashion. 

For Linux users, using the "Set Path" dialog box requires write access to 
pathdef.m. This file can be found under <...matlabroot...>/toolbox/local. To
find where MATLAB is installed, type "matlabroot" at the MATLAB command line.

Alternatively, the toolbox can be installed by adding the line 

    addpath('<...pathname...>/k-Wave');
    
to the startup.m file, where <...pathname...> is replaced with the location 
of the toolbox, and the slashes should be in the direction native to your 
operating system. If no startup.m file exists, create one, and save it in 
the MATLAB startup directory. 

After installation, restart MATLAB. You should then be able to see the 
k-Wave help files in the MATLAB help browser. This can be accessed by 
selecting "k-Wave Toolbox" from the contents page. Try selecting one of the
examples and then clicking "run the file". 

If you can't see "k-Wave Toolbox" in the contents list of the MATLAB help 
browser, try typing "help k-Wave" at the command prompt to see if the 
toolbox has been installed correctly. If it has and you still can't see the
help files, open "Preferences" and select "Help" and make sure "k-Wave 
Toolbox" or "All Products" is checked. 

After installation, to make the k-Wave documentation searchable from within
the MATLAB help browser, run

    builddocsearchdb(`<...pathname...>/k-Wave/helpfiles');
    
again using the slash direction native to your operating system. Note, the
created database file will only work with the version of MATLAB used to 
create it.

If using the C++ or CUDA versions of kspaceFirstOrder3D, the appropriate 
binaries (and library files if using Windows) should also be downloaded 
from http://www.k-wave.org/download.php and placed in the root "binaries"
folder of the toolbox.
____________________________________________________________________________

RELEASE NOTES
____________________________________________________________________________

New Features and Changes:
- axisymmetric simulations are now supported using kspaceFirstOrderAS and 
  kspaceFirstOrderASC
- single-frequency simulations in homogeneous media can be computed without 
  time-stepping using acousticFieldPropagator and acousticFieldPropagatorC
- time-varying sources in kspaceFirstOrder1D, kspaceFirstOrder2D, and 
  kspaceFirstOrder3D (and the corresponding C++ codes) now include a k-space
  correction which improves accuracy for small numbers of points per period
- legacy behaviour for time-varying sources can be obtained by setting 
  source.p_mode = 'additive-no-correction' and source.u_mode = 
  'additive-no-correction'
- holographic projections of planar input data can be performed using 
  angularSpectrum and angularSpectrumCW
- measured pressure fields can be mapped to k-Wave inputs for accurate 
  holographic projections using calculateMassSource and calculateMassSourceCW
- 'PMLSize' can now be set to 'auto' to automatically choose grid sizes with 
  small prime factors
- 2D simulations can now be run using optimised C++ and C++/CUDA codes using 
  kspaceFirstOrder2DC and kspaceFirstOrder2DG
- kspaceFirstOrder3DC (etc) now automatically calls the combine_sensor_data 
  method if an object of the kWaveTransducer class is used as a sensor
- kspaceFirstOrder3DC (etc) now supports optional inputs to define the number 
  of threads, thread binding, and the verbosity level
- the compiled C++ codes have been combined into two binaries now called 
  kspaceFirstOrder-OMP (which supports 2D, 3D, and axisymmetric domains) 
  and kspaceFirstOrder-CUDA (which supports 2D and 3D domains)
- the input file for the C++ code has been updated to version 1.2 (the k-space
  and shift variables, and PML vectors are no longer required)
- pstdElastic2D and pstdElastic3D can now return the particle velocity split 
  into compressional and shear components by setting sensor.record = 
  {'u_split_field'}
- kWaveDiffusion now allows command line updates to be suppressed by setting 
  the optional input 'DisplayUpdates', false
- kWaveDiffusion now prints a warning if dimension sizes have high prime 
  factors
- toneBurst now allows the number of ring-up and ring-down cycles to be 
  specified
- makeDisc and makeBall now allow non-integer radius values and maintain 
  correct radius on axis
- spect and extractAmpPhase now work for 4D input matrices
- waterAbsorption now allows temperature to be defined as a vector
- getWin now allows 'Symmetry' input to be defined as a vector
- smooth function inputs have changed (kgrid input no longer required)

Bug Fixes:
- bug fix in waterSoundSpeed for matrix inputs (generated error)
- bug fix in focusedBowlONeil when axial_position = radius (sometimes 
  returned 0)
- bug fix in getBLI for functions with odd numbers of grid points (used 
  incorrect wavenumbers)
- bug fix in extractAmpPhase for optional input 'Dim', 1 (generated error)
- bug fix in kWaveDiffusion when using the plotTemp method in 3D with an odd
  number of grid points (generated error)
- bug fix in smooth for matrices with even numbers of grid points 
 (incorrectly filtered DC component)
- bug fix in Simulating B-mode Ultrasound Images and Simulating B-mode 
  Images Using A Phased Array examples (attenuation value for time gain 
  compensation given in incorrect units)

New Functions:
- acousticFieldPropagator
- acousticFieldPropagatorC
- angularSpectrum
- angularSpectrumCW
- calculateMassSource
- calculateMassSourceCW
- getOptimalPMLSize
- kspaceFirstOrder2DC
- kspaceFirstOrder2DG
- kspaceFirstOrderAS
- kspaceFirstOrderASC
- reorderBinarySensorData
- roundEven
- roundOdd
- waterDensity
- waterNonlinearity

Deprecated Functions:
- speedSoundWater (renamed to waterSoundSpeed)
- attenuationWater (renamed to waterAbsorption)

New Examples:
- Simulations In An Axisymmetric Coordinate System
- Simulating CW Fields Using The Acoustic Field Propagator
- Holographic Projections Using The Angular Spectrum Method
- Equivalent Source Holography

____________________________________________________________________________

LICENSE
____________________________________________________________________________

k-Wave (c) 2009-2020 Bradley Treeby, Ben Cox, and Jiri Jaros (see individual
files for list of authors).

The k-Wave toolbox is distributed by the copyright owners under the terms of
the GNU Lesser General Public License (LGPL) which is a set of additional 
permissions added to the GNU General Public License (GPL). The full text of 
both licenses is included with the toolbox in the folder 'license'.

The licence places copyleft restrictions on the k-Wave toolbox. Essentially,
anyone can use the software for any purpose (commercial or non-commercial), 
the source code for the toolbox is freely available, and anyone can 
redistribute the software (in its original form or modified) as long as the
distributed product comes with the full source code and is also licensed 
under the LGPL. You can make private modified versions of the toolbox 
without any obligation to divulge the modifications so long as the modified
software is not distributed to anyone else. The copyleft restrictions only 
apply directly to the toolbox, but not to other (non-derivative) software 
that simply links to or uses the toolbox. 

k-Wave is distributed in the hope that it will be useful, but WITHOUT ANY 
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
details (http://www.gnu.org/licenses/lgpl.html). 

If you find the toolbox useful for your academic work, please consider 
citing one or more of the following papers:

1. Overview of the toolbox with applications in photoacoustics:

   B. E. Treeby and B. T. Cox, "k-Wave: MATLAB toolbox for the simulation  
   and reconstruction of photoacoustic wave-fields," J. Biomed. Opt., vol. 
   15, no. 2, p. 021314, 2010.

2. Nonlinear ultrasound model and the C++ code:

   B. E. Treeby, J. Jaros, A. P. Rendell, and B. T. Cox, "Modeling nonlinear 
   ultrasound propagation in heterogeneous media with power law absorption 
   using a k-space pseudospectral method," J. Acoust. Soc. Am., vol. 131, 
   no. 6, pp. 4324-4336, 2012. 

3. Elastic wave model:

   B. E. Treeby, J. Jaros, D. Rohrbach, B. T. Cox , "Modelling elastic wave 
   propagation using the k-Wave MATLAB toolbox," IEEE International 
   Ultrasonics Symposium, pp. 146-149, 2014.
____________________________________________________________________________