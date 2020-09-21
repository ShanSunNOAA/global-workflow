# How to run global-workflow on hera using singularity

These are the steps you need to do to run GFS v16b workflow using rocoto

## Getting the image

First you need to get a copy of the docker image for the global-workflow
   
    docker pull dshawul/gfs-gnu

Then, convert the docker image to singularity image using

    singularity pull docker://dshawul/gfs-gnu

You can't do these steps directly on hera so you will have to do it on your laptop
and copy the singularity image to hera.

## Sandbox

We will extract the singularity image to a "sandbox" as it is more convienient
and faster to run and work with. The sandbox is a regular directory with all contents
of the image.

    singularity build --sandbox workflow gfs-gnu\_latest.sif

The directory `workflow` contains the contents of the image, and you can find global-workflow
under `workflow/opt/global-workflow`. You can setup a test case and run forecast using
this directory in place of the raw singularity image.

## Setting environement variables

This particular image uses GNU compilers and MPICH library so we will load modules that
will work with it. Moreover, we need to set environement variables needed for running
the workflow. Here is the content of my `set_environment.sh` script I use for this purpose

    #!/bin/tcsh
    
    set COLON=':'
    setenv GFS_FIX_DIR "/scratch1/NCEPDEV/global/glopara/fix"
    setenv GFS_IMG_DIR "/scratch2/BMC/gsd-hpcs/NCEPDEV/stmp3/Daniel.Abdi/containers/workflow"
    setenv GFS_NPE_NODE_MAX 24
    setenv GFS_SING_CMD "singularity exec --bind $GFS_FIX_DIR$COLON/fix $GFS_IMG_DIR run_bash_command"
    setenv GFS_DAEMON_RUN "$GFS_IMG_DIR/opt/global-workflow/cloud/scripts/run_sing_job.sh"
    setenv GFS_DAEMON_KILL "$GFS_IMG_DIR/opt/global-workflow/cloud/scripts/kill_sing_job.sh"
    
    module use /scratch2/BMC/gsd-hpcs/bass/modulefiles/ 
    module use /scratch2/BMC/gsd-hpcs/dlibs/modulefiles/ 
    
    module purge
    module load rocoto
    module load hpss
    module load gcc/9.3.0
    module load mpich/3.3a2

Then we source this script
   
    source ./set_environment.sh

## Setting up a test case

To setup a test case, we follow the same procedure as the one used without containers.
We write a script to set paths for EXPDIR, COMROT etc. Here is an example script for the C48 test case

    COMROT=/scratch2/BMC/gsd-hpcs/NCEPDEV/global/noscrub/$USER/fv3gfs/comrot ## default COMROT directory
    EXPDIR=/scratch2/BMC/gsd-hpcs/NCEPDEV/global/save/$USER/fv3gfs/expdir    ## default EXPDIR directory
    PTMP=/scratch2/BMC/gsd-hpcs/NCEPDEV/stmp2/$USER                          ## default PTMP directory
    STMP=/scratch2/BMC/gsd-hpcs/NCEPDEV/stmp4/$USER                          ## default STMP directory
    
    GITDIR=$GFS_IMG_DIR/opt/global-workflow
    #GITDIR=/opt/global-workflow
    #    ICSDIR is assumed to be under $COMROT/FV3ICS
    #         create link $COMROT/FV3ICS to point to /scratch4/BMC/rtfim/rtruns/FV3ICS
    
    
    PSLOT=c48
    IDATE=2018082700
    EDATE=2018082700
    RESDET=48               ## 96 192 384 768
    GFSCYCLE=2
    
    
    ./setup_expt_fcstonly.py --pslot $PSLOT  \
           --gfs_cyc $GFSCYCLE --idate $IDATE --edate $EDATE \
           --configdir $GITDIR/parm/config \
           --res $RESDET --comrot $COMROT --expdir $EXPDIR
    
    
    #for running chgres, forecast, and post 
    ./setup_workflow_fcstonly.py --expdir $EXPDIR/$PSLOT

Note that the `GITDIR` variable points to the location of our sandbox for the singularity image.
Save this script as c48.sh under `$GFS_IMG_DIR/opt/global-workflow/ush/rocoto`.

## Modifying setup\_workflow\_fcstonly.py

Before running our case setup script, we need to modify the python scripts that generate the xml
file needed by rocoto workflow manager. At the top of this script, the tasks you want to run can
be specified. There are many tasks we don't want to run for this example, such as a bunch of "wave processing"
steps that are recently added to global-workflow. The simples workflow is to do forecast with exisiting initial conditions

    taskplan = [ 'fcst', 'post' ]

If you the ability to get restricted data from HPSS, use this instead

    taskplan = [ 'getic', 'fv3ic', 'fcst', 'post' ]

Then, comment out the steps you don't need in the `get\_workflow` function

## Generating the test case directories and setting up a run

We can now run the c48.sh script to generate the directories and scripts needed for running the C48 workflow.
Under our experiment directory, we find a bunch of scripts sourced during the run.
We will modify a couple of them to fit our needs

### config.base

Set the machine to LINUX

    export machine="LINUX"

Set account to gsd-hpcs for hera

    export ACCOUNT="gsd-hpcs"

Set HOMEDIR, STMP, and PTMP to the right locations

    export HOMEDIR="/scratch1/BMC/gsd-hpcs/NCEPDEV/global/$USER"
    export STMP="/scratch1/BMC/gsd-hpcs/NCEPDEV/stmp2/$USER"
    export PTMP="/scratch1/BMC/gsd-hpcs/NCEPDEV/stmp4/$USER"

Set LEVS to 65 instead of 128. The new default of LEVS=128 does not work properly for some reason

    export LEVS=65

Comment out or set to .false. the inline postprocessing option
   
    export WRITE\_DOPOST=".fase."

Set to NO wave processing, and optionally gldas
 
    export DO\_WAVE=NO
    export DO\_GLDAS=NO

You can set the hours of forecast and write interval, e.g. for 3 hrs fcst 

    export FHMAX\_GFS\_00=3
    export FHMAX\_GFS\_06=3
    export FHMAX\_GFS\_12=3
    export FHMAX\_GFS\_18=3
   
    export FHOUT\_GFS=3

### config.fv3

Here is where you control the number of mpi ranks and threads for your test case
if you so wish. Usually leave it to default.

Just as an example, to run C48 with as low as 6 mpi ranks, modify as follows

    export layout\_x=1
    export layout\_y=1
    export layout\_x\_gfs=1
    export layout\_y\_gfs=1

To use just 1 mpi rank for writing output

    export WRITE\_GROUP=1
    export WRTTASK\_PER\_GROUP=1
    export WRITE\_GROUP\_GFS=1
    export WRTTASK\_PER\_GROUP\_GFS=1

### config.fcst

There is a variable defined here for io\_layout that you may need to turn off in some cases
This is a new additon in v16b and may already have been removed in other branches of GFS.

    #export io\_layout=4,4

### the rocoto xml file, c48.xml

Our script for generating test case has the full path to the sandbox specified in GITDIR.
However, once running inside a container, the full path is not needed and infact won't work.
So we shorten the `HOMEgfs` and `JOBS_DIR` directory to

    <!ENTITY HOMEgfs  "/opt/global-workflow">
    <!ENTITY JOBS_DIR "/opt/global-workflow/jobs/rocoto">  

Then, we change to exporting all environment variables when launching jobs. This is needed
when working with containers

    <!ENTITY NATIVE_FCST_GFS    "--export=ALL">

Do the same for other steps of the workflow you need to run.
To modify the number of nodes, processors per node etc, if you need to

    <!ENTITY RESOURCES_FCST_GFS "<nodes>1:ppn=40:tpp=1</nodes>">

When running any job, we have to launch a daemon process on the host to process SLURM srun
commands issued from within the container. For this reason, we have to suffix and prefix
the job commands with environement variables we defined in `set_environement.sh`.
Also here is where we apply the `singularity exec` command needed for running executables within the image.
For example, the post processing job can be modified as

    <command>$GFS\_DAEMON\_RUN; $GFS\_SING\_CMD &JOBS\_DIR;/post.sh; $GFS\_DAEMON\_KILL</command>
   
This step and the steps for exporting environement variables and setting ppn can be done by modifying
the python scripts instead, so that we don't have to do it everytime.

## Running the test case

Now that the test case is setup we can run different steps of the workflow using rocoto.
There is no difference with running GFS on hera without containers

If you don't have restricted data access but have some initial conditions for the forecast,
you have to symlink the INPUT directory to the initial conditons stored under COMROT.
From the COMROT directory, I do the following for the C48 test case

    ln -sf $COMROT/FV3ICS/2018082700/gfs/C48/INPUT $COMROT/gfs.20180827/00/atmos/INPUT

If you do have restricted access, the first two steps of the workflow `gfsfv3ic` and `gfsfcst`
will generate the initial condition for you.

To run a specific step of the workflow

    rocotoboot -w c48.xml -d c48.db -c all -t gfsgetic

To run one step after another, use rocotorun instead

    rocotorun -w c48.xml -d c48.db

Log files for your runs are stored under $COMROT/c48/logs, so you can investigate there
if something goes wrong.
   


