[![Build htf](https://github.com/clouden90/ufs-srweather-app/actions/workflows/build.yml/badge.svg?branch=ctest)](https://github.com/clouden90/ufs-srweather-app/actions/workflows/build.yml)

# Build HTF test for the UFS Short-Range Weather App

## ctest (for Hierarchical Testing Framework, HTF)

Currently, the following configurations are supported/tested:

Machine     | Orion       | NOAA Cloud (AWS & GCPv2)   |
------------| ------------|--------|
Compiler(s) | Intel, GNU  | Intel  |

## How to use

Currently there are 5 tests (after build step, you can type ``ctest -N`` to see the list) existed.
System requirements: at least 12-core cpus, 16gb memory, and 60gb disk space

```
[Yi-cheng.Teng@awsnoaa-1 test]$ ctest -N
Test project /lustre/ufs-srweather-app/build/test
  Test #1: test_ccpp_scm_fv3
  Test #2: test_fv3_regional_noquilt
  Test #3: test_fv3_regional_upp
  Test #4: test_fv3_regional_stoch
  Test #5: test_regional_workflow

Total Tests: 5
```

On NOAA Cloud (AWS for example):


```
git clone -b ctest https://github.com/clouden90/ufs-srweather-app.git
cd ufs-srweather-app
./manage_externals/checkout_externals -o
source htf/machines/orion_intel.env
mkdir build
cd build
cmake -DBUILD_CCPP-SCM=ON -DBUILD_UFS_UTILS=ON -DBUILD_UPP=ON .. -DCMAKE_INSTALL_PREFIX=..
make -j4
cd test
sbatch job_card_orion

```
And You can check your slurm output. It should contain something like:

```
[Yi-cheng.Teng@awsnoaa-1 test]$ ctest
Test project /lustre/ufs-srweather-app/build/test
    Start 1: test_ccpp_scm_fv3
1/5 Test #1: test_ccpp_scm_fv3 ................   Passed    6.78 sec
    Start 2: test_fv3_regional_noquilt
2/5 Test #2: test_fv3_regional_noquilt ........   Passed   74.70 sec
    Start 3: test_fv3_regional_upp
3/5 Test #3: test_fv3_regional_upp ............   Passed   70.53 sec
    Start 4: test_fv3_regional_stoch
4/5 Test #4: test_fv3_regional_stoch ..........   Passed   72.39 sec
    Start 5: test_regional_workflow
5/5 Test #5: test_regional_workflow ...........   Passed  856.20 sec

100% tests passed, 0 tests failed out of 5

Total Test time (real) = 1080.64 sec
```

Or on Orion:

```
Test project /work/noaa/epic-ps/ycteng/case/20220524/ufs-srweather-app/build/test
    Start 1: test_ccpp_scm_fv3
1/5 Test #1: test_ccpp_scm_fv3 ................   Passed    9.27 sec
    Start 2: test_fv3_regional_noquilt
2/5 Test #2: test_fv3_regional_noquilt ........   Passed   78.67 sec
    Start 3: test_fv3_regional_upp
3/5 Test #3: test_fv3_regional_upp ............   Passed   71.81 sec
    Start 4: test_fv3_regional_stoch
4/5 Test #4: test_fv3_regional_stoch ..........   Passed   73.90 sec
    Start 5: test_regional_workflow
5/5 Test #5: test_regional_workflow ...........   Passed  1266.89 sec

100% tests passed, 0 tests failed out of 5

Total Test time (real) = 1500.55 sec
```
Additionally, user can adjust ``default_vars.sh`` to run test#5 with differnt resolution/physical suite/number of cores/length of forecast.

## Create case script for HTF
The user can also use ``create_case.sh`` script to generate new case using regional workflow with desired setup (e.g. platform, grid, physical suite, [selected event](https://ufs-case-studies.readthedocs.io/en/develop/2019Barry.html))

```
$ ./create_case.sh -h
Usage: ./create_case.sh --platform=PLATFORM --account=ACCOUNT [OPTIONS]...

OPTIONS
  -h, --help
      show this help guide
  -p, --platform=PLATFORM
      name of machine you are building on
      (e.g. cheyenne | hera | jet | orion | wcoss_dell_p3 | wcoss2)
  --account=ACCOUNT
      account on hpc machine
  --compiler=COMPILER
      compiler to use; default depends on platform
      (e.g. intel | gnu | cray | gccgfortran)
  --case=CASE
      weather model case study
      (e.g. 2019_BARRY)
  --grid=GRID_NAME
      grid name
      (e.g. RRFS_CONUS_25km)
  --fcst_hr=FCST_HRS
      FCST HR (default: 3)
  --ccpp=CCPP_SUITE
      CCPP suite
  --layout_x=LAYOUTX
      layout x
  --layout_y=LAYOUTY
      layout y
  --wtime=WTIME
      WALL TIME (e.g. "01:00:00")
  --exp-dir=EXP_DIR
      build directory
  -v, --verbose
      build with verbose output
      
./create_case.sh --platform=orion --account=epic-ps --grid=RRFS_CONUS_25km --fcst_hr=3 --ccpp=FV3_GFS_v16 --case=2019_BARRY --wtime="02:00:00" --layout_x=10 --layout_y=6 -v

```
Then follow instruction shown on screen to run your case using rocoto. 

Below is an example to use htf-ctest to check results from ccpp-scm (t profiles):
![profiles_mean_T](https://user-images.githubusercontent.com/30629225/173900650-9227d4f2-cd25-42a3-8388-f661c5df14d3.png)

Below is an example to use ``create_case.sh`` with different ccpp suites and compared with best track:

![Screen Shot 2022-06-03 at 12 34 55 PM](https://user-images.githubusercontent.com/30629225/171907971-092760fa-c566-4a8e-a571-f5da4a972a91.png)

## CI test
Currently, a CI test thru git action for HTF is added (check [here](https://github.com/clouden90/ufs-srweather-app/runs/6924907844?check_suite_focus=true))  
