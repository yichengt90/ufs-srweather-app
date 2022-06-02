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
  Test #1: test_ccpp
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
source test/machines/noaacloud_aws_intel.env
mkdir build
cd build
cmake -DBUILD_CCPP-SCM=ON .. -DCMAKE_INSTALL_PREFIX=..
make -j4
cd test
sbatch job_card

```
And You can check your slurm output. It should contain something like:

```
Test project /lustre/ufs-srweather-app/build/test
    Start 1: test_ccpp
1/5 Test #1: test_ccpp ........................   Passed    6.78 sec
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
    Start 1: test_ccpp
1/5 Test #1: test_ccpp ........................   Passed    9.27 sec
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
Additionally, the user can modify test/default_vars.sh to run test#5 with differnt resolution/physical suite/number of cores/length of forecast.
