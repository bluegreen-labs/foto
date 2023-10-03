Dear CRAN team,

This is an update of the foto package, to remove dependencies on the raster package.

The package now uses terra in the calculation of fourier transform textural ordination values.

Code coverage unit tests remains the same at 97%. No additional functionality is included.

Kind regards, Koen Hufkens

## test environments, local, github actions and r-hub

- Ubuntu 22.04 install on R 4.3
- github actions on Ubuntu 22.04 (devel / release)
- github actions on Windows and MacOS
- codecove.io code coverage at ~97%

## local / Travis CI R CMD check results

0 errors | 0 warnings | 0 notes