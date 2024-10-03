# Statistical Learning Virtual Machine

*Author*: Timm Nawrocki, Alaska Center for Conservation Science

*Last Updated*: 2021-08-21

*Description*: Instructions to create a virtual machine (vm) instance on Google Cloud Compute configured with 4 vCPUs, 16 GB of CPU memory, a 500 GB persistent disk, and Ubuntu 20.04 LTS operating system. The machine will be capable of running the python scripts from the project repository through a web browser Linux command line interface. Most of the Google Cloud Compute Engine configuration can be accomplished using the browser interface, which is how configuration steps are explained in this document. If preferred, all of the configuration steps can also be scripted using the Google Cloud SDK. Users should download and install the [Google Cloud SDK](https://cloud.google.com/sdk/) regardless because it is necessary for batch file uploads and downloads.

## 1. Configure project
Create a new project if necessary and enable API access for Google Cloud Compute Engine.

### Create a storage bucket for the project
Create a new storage bucket. Select "multiregional" and make the region the same as the region that your virtual machine will be in. If your virtual machines must be in multiple regions, it is not necessary to have a bucket for each region if you will just be uploading and downloading files between the two.

The storage bucket in this example is named "moose-southwest".

Use the "gsutil cp -r" command in Google Cloud SDK to copy data to and from the bucket. Example:

```
gsutil cp -r gs://moose-southwest/example/* ~/example/
```

The '*' is a wildcard. The target directory should already exist in the virtual machine or local machine. If the google bucket is the target, the bucket will create a new directory from the copy command. Load all necessary data for analysis into the google bucket. This is most easily done using the Google Cloud SDK rather than the browser interface.

## 2. Configure a new vm instance
The following steps must be followed every time a new instance is provisioned. The first vm will serve as a image template for the additional vms. The software and data loaded on the template vm are exported as a custom disk image along with the operating system. Each additional instance can use the custom disk image rather than requiring independent software installation and data upload.

### Create a new instance with the following features:

*Name*: instance-#

*Region*: us-west1 (Oregon)

*Zone*: us-west1-b

*Machine type*: 4 vCPUs (16 GB memory)

*Boot disk*: Ubuntu 20.04 LTS

*Boot disk type*: Standard Persistent Disk

*Size (GB)*: 500

*Service account*: Compute Engine default service account

*Access scopes*: Allow full access to all Cloud APIs

*Firewall*: Allow HTTP Traffic, Allow HTTPS traffic

After hitting the create button, the new instance will start automatically.

Launch the terminal in a browser window using ssh.

### Set up the system environment:

Update the system prior to installing software and then install necessary base packages.

```
sudo apt-get update
sudo apt-get install vim
```

Install latest Anaconda release. The version referenced in the example below may need to be updated. The repository version should match the Ubuntu Linux release version.

```
wget https://repo.anaconda.com/archive/Anaconda3-2021.05-Linux-x86_64.sh
bash Anaconda3-2021.05-Linux-x86_64.sh
```

At the option to prepend the Anaconda3 install location to PATH in your home directory, hit enter. At the option to  initialize Anaconda 3, type "yes".

Remove the installation file, start bashrc, and update all packages using conda.

```
rm Anaconda3-2021.05-Linux-x86_64.sh
source ~/.bashrc
```

#### Download files to the virtual machine:

Make directories as needed on the vm and copy data and files from the Google Cloud bucket to the vm folders.

```
cd ~
mkdir ~/example
gsutil cp -r gs://beringia/example/* ~/example/
```

#### Add the repository path to the bashrc file:

Add the repository path to the PYTHONPATH variable so that Python can find the local packages in the repository. First, open the bashrc file using "vi .bashrc". At the bottom of the file, add the following line (to edit in vim, type "i"):

```
export PYTHONPATH=$PYTHONPATH:/home/twnawrocki/repository
```

To save and exit vim, hit the "Esc" key and type ":wq" followed by the enter key. Then type "source ~/.bashrc" into the terminal.

### Create a custom disk image from template vm:

Creating a custom disk image will allow additional vms to be created that are identical to the template including all files and installed software. This can save much time when creating clusters of vms.
1. Stop the vm
2. Select Compute Engine -> Images
3. Click 'Create Image'
4. Name the image
5. Leave 'Family' blank
6. Select the template vm as the 'Source disk'

Once the image creates successfully, other vm can be created using the custom image, obviating the need to install software and load files for each vm independently.

## 3. Run script
To run the script, simply execute the file in python3. Use vim to edit the script as necessary prior to execution (e.g., to update file paths).

```
# Execute with messages (will stop on closing terminal)
python3 ~/repository/statistics_PathSelection/HabitatPredict.py

# OR execute without messages (will continue whether terminal is open or closed)
nohup python3 ~/repository/statistics_PathSelection/HabitatPredict.py
```

**IMPORTANT: When finished, the instance must be stopped to prevent being billed additional time.**

The instance can be stopped in the browser interface or by typing the following command into the Google Cloud console:

```
gcloud compute instances stop --zone=us-west1-b <instance_name>
```
