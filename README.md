# How To Build a Hashicorp Vault Server Using Packer and Terraform on DigitalOcean [Quickstart]

https://www.digitalocean.com/community/tutorials/how-to-build-a-hashicorp-vault-server-using-packer-and-terraform-on-digitalocean-quickstart

Configuration Management Quickstart Terraform Automated Setups

By Savic

Published on March 9, 2020 7.3kviews
## Introduction
Vault, by Hashicorp, is an open-source tool for securely storing secrets and sensitive data in dynamic cloud environments. Packer and Terraform, also developed by Hashicorp, can be used together to create and deploy images of Vault.

In this tutorial, you’ll use Packer to create an immutable snapshot of the system with Vault installed, and orchestrate its deployment using Terraform.

For a more detailed version of this tutorial, please refer to How To Build a Hashicorp Vault Server Using Packer and Terraform on DigitalOcean.

## Prerequisites

- Packer installed on your local machine. For instructions, visit the [official documentation](https://www.packer.io/intro/getting-started/install.html).
- Terraform installed on your local machine. Visit the [official documentation](https://learn.hashicorp.com/terraform/getting-started/install.html) for a guide.
- A personal access token (API key) with read and write permissions for your DigitalOcean account. Visit [How to Create a Personal Access Token](https://www.digitalocean.com/docs/api/create-personal-access-token/) to create one.
- An SSH key you’ll use to authenticate with the deployed Vault Droplets, available on your local machine and added to your DigitalOcean account. You’ll also need its fingerprint, which you can copy from the [Security](https://cloud.digitalocean.com/account/security) page of your account once you’ve added it. See the [DigitalOcean documentation(https://www.digitalocean.com/docs/droplets/how-to/add-ssh-keys/)] for detailed instructions or the [How To Set Up SSH Keys tutorial](https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys-on-ubuntu-1804).

### to get the SSH Fingerprint

```java
doctl compute ssh-key list
ID          Name           FingerPrint
3069***    my-key-name    11:33:44:22:33:55:03:09:f5:57:f2:97:24:d8:0a:21
```

## Step 1 — Creating a Packer Template
Create and move into the ~/vault-orchestration directory to store your Vault files:

```java
mkdir ~/vault-orchestration
cd ~/vault-orchestration
```
 
Create separate directories for Packer and Terraform configuration by running:

```java
mkdir packer terraform
```
 
Navigate to the Packer directory:

```java
cd packer
```
 
## Using Template Variables
Create a variables.json in your packer subdirectory to store your private variable data:

```java
nano variables.json
```
 
Add the following lines:

~/vault-orchestration/packer/variables.json

```java
{
  "do_token": "your_do_api_key",
  "base_system_image": "ubuntu-18-04-x64",
  "region": "nyc3",
  "size": "s-1vcpu-1gb"
}
```
 
You’ll use these variables in the template you are about to create. You can edit the base image, region, and Droplet size values according to the developer docs.

Replace your_do_api_key with your API key, then save and close the file.

## Creating Builders and Provisioners
Create your Packer template for Vault in a file named template.json:

```java
nano template.json
```
 
Add the following lines:

~/vault-orchestration/packer/template.json

```java
{
   "builders": [{
       "type": "digitalocean",
       "api_token": "{{user `do_token`}}",
       "image": "{{user `base_system_image`}}",
       "region": "{{user `region`}}",
       "size": "{{user `size`}}",
       "ssh_username": "root"
   }],
   "provisioners": [{
       "type": "shell",
       "inline": [
           "sleep 30",
           "sudo apt-get update",
           "sudo apt-get install cockpit",
           "sudo apt-get install unzip -y",
           "curl -L https://releases.hashicorp.com/vault/1.3.2/vault_1.3.2_linux_amd64.zip -o vault.zip",
           "unzip vault.zip",
           "sudo chown root:root vault",
           "mv vault /usr/local/bin/",
           "rm -f vault.zip"
       ]
}]
}
```
 
You define a single digitalocean builder. Packer will create a temporary Droplet of the defined size, image, and region using the provided API key.

The provisioner will connect to it using SSH with the specified username and will sequentially execute all defined provisioners before creating a DigitalOcean Snapshot from the Droplet and deleting it.

It’s of type shell, which will execute given commands on the target. The commands in the template will wait 30 seconds for the system to boot up, and will then download and unpack Vault 1.3.2. Check the official Vault download page for the most up-to-date version for Linux.

Save and close the file.

## Verify the validity of your template:

```java
packer validate -var-file=variables.json template.json
```
 
You’ll see the following output:

```java
Output
Template validated successfully.
```

## Step 2 — Building the Snapshot
Build your snapshot with the Packer build command:

```java
packer build -var-file=variables.json template.json
```
 
You’ll see a lot of output, which will look like this:

```java
Output
digitalocean: output will be in this color.

==> digitalocean: Creating temporary ssh key for droplet...
==> digitalocean: Creating droplet...
==> digitalocean: Waiting for droplet to become active...
==> digitalocean: Using ssh communicator to connect: ...
==> digitalocean: Waiting for SSH to become available...
==> digitalocean: Connected to SSH!
==> digitalocean: Provisioning with shell script: /tmp/packer-shell035430322
...
==> digitalocean:   % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
==> digitalocean:                                  Dload  Upload   Total   Spent    Left  Speed
  digitalocean: Archive:  vault.zip
==> digitalocean: 100 45.5M  100 45.5M    0     0   154M      0 --:--:-- --:--:-- --:--:--  153M
  digitalocean:   inflating: vault
==> digitalocean: Gracefully shutting down droplet...
==> digitalocean: Creating snapshot: packer-1581537927
==> digitalocean: Waiting for snapshot to complete...
==> digitalocean: Destroying droplet...
==> digitalocean: Deleting temporary ssh key...
Build 'digitalocean' finished.

==> Builds finished. The artifacts of successful builds are:
--> digitalocean: A snapshot was created: 'packer-1581537927' (ID: 58230938) in regions '...'
```

The last line contains the name of the snapshot (such as packer-1581537927) and its ID in parentheses, highlighted here. Note your ID of the snapshot, because you’ll need it in the next step.

If the build process fails due to API errors, wait a few minutes and then retry.

## Step 3 — Writing Terraform Configuration
Navigate to the terraform subdirectory:

```java
cd ~/vault-orchestration/terraform
```
 
Create a file named `do-provider.tf` to store the provider:

```java
nano do-provider.tf
```
 
Add the following lines:

~/vault-orchestration/terraform/do-provider.tf

```java
variable "do_token" {
}

variable "ssh_fingerprint" {
}

variable "instance_count" {
default = "1"
}

variable "do_snapshot_id" {
}

variable "do_name" {
default = "vault"
}

variable "do_region" {
}

variable "do_size" {
}

variable "do_private_networking" {
default = true
}

provider "digitalocean" {
token = var.do_token
}
```
 
This file provides the digitalocean provider with an API key. To specify the values of these variables you’ll create a variable definitions file similarly to Packer. The filename must end in either `.tfvars` or `.tfvars.json`.

Save and close the file.

## Create a variable definitions file for packer:

```java
nano definitions.tfvars
```
 
Add the following lines:

~/vault-orchestration/packer/definitions.tf

```java
do_token         = "your_do_api_key"
ssh_fingerprint  = "your_ssh_key_fingerprint"
do_snapshot_id   = your_do_snapshot_id
do_name          = "vault"
do_region        = "nyc3"
do_size          = "s-1vcpu-1gb"
instance_count   = 1
```
 
## Create a variable definitions file for terraform:

```java
nano definitions.tfvars
```
 
Add the following lines:

~/vault-orchestration/terraform/definitions.tf

```java
do_token         = "your_do_api_key"
ssh_fingerprint  = "your_ssh_key_fingerprint"
do_snapshot_id   = your_do_snapshot_id
do_name          = "vault"
do_region        = "nyc3"
do_size          = "s-1vcpu-1gb"
instance_count   = 1
```
 
Replace your_do_api_key, your_ssh_key_fingerprint, and your_do_snapshot_id (the snapshot ID you noted from the previous step). The do_region and do_size parameters must have the same values as in the Packer variables file.

Save and close the file.

## Create the following file to store the Vault snapshot deployment configuration:

```java
nano deployment.tf
```
 
Add the following lines:

~/vault-orchestration/terraform/deployment.tf

```java
resource "digitalocean_droplet" "vault" {
count              = var.instance_count
image              = var.do_snapshot_id
name               = var.do_name
region             = var.do_region
size               = var.do_size
private_networking = var.do_private_networking
ssh_keys = [
  var.ssh_fingerprint
]
}

terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
    }
  }
}

output "instance_ip_addr" {
value = {
  for instance in digitalocean_droplet.vault:
  instance.id => instance.ipv4_address
}
description = "The IP addresses of the deployed instances, paired with their IDs."
}
```
 
You define a single resource of the type digitalocean_droplet named vault. You set its parameters according to the variable values and add an SSH key (using its fingerprint) from your DigitalOcean account to the Droplet resource. You output the IP addresses of all newly deployed instances to the console.

Save and close the file.

## Initialize the directory as a Terraform project:

```java
terraform init
```
 
You’ll see the following output:

```java
Output

Initializing the backend...

Initializing provider plugins...

The following providers do not have any version constraints in configuration,
so the latest version was installed.

To prevent automatic upgrades to new major versions that may contain breaking
changes, it is recommended to add version = "..." constraints to the
corresponding provider blocks in configuration, with the constraint strings
suggested below.

* provider.digitalocean: version = "~> 1.14"

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

## Step 4 — Deploying Vault Using Terraform
Test the validity of your configuration:

```java
terraform validate
```
 
You’ll see the following output:

```java
Output
Success! The configuration is valid.
```

Run the plan command to see what Terraform will attempt when it comes to provision the infrastructure:

```java
terraform plan -var-file="definitions.tfvars"
```
 
The output will look similar to:

```java
Output
Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.


------------------------------------------------------------------------

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
+ create

Terraform will perform the following actions:

# digitalocean_droplet.vault[0] will be created
+ resource "digitalocean_droplet" "vault" {
  ...
  }

Plan: 1 to add, 0 to change, 0 to destroy.

------------------------------------------------------------------------

Note: You didn't specify an "-out" parameter to save this plan, so Terraform
can't guarantee that exactly these actions will be performed if
"terraform apply" is subsequently run.
```


Execute the plan:

```java
terraform apply -var-file="definitions.tfvars"
```
 
The Droplet will finish provisioning and you’ll see output similar to this:

```java
Output
An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
+ create

Terraform will perform the following actions:

+ digitalocean_droplet.vault-droplet

...

Plan: 1 to add, 0 to change, 0 to destroy.

...

digitalocean_droplet.vault-droplet: Creating...

...

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

instance_ip_addr = {
"181254240" = "your_new_server_ip"
}
```

## Step 5 — Verifying Your Deployed Droplet
Run the following to connect to your new Droplet:

```java
ssh root@your_server_ip
```
 
Once you are logged in, run Vault with:

```java
vault
```
 
You’ll see its “help” output:

```java
Output
Usage: vault <command> [args]

Common commands:
  read        Read data and retrieves secrets
  write       Write data, configuration, and secrets
  delete      Delete secrets and configuration
  list        List data or secrets
  login       Authenticate locally
  agent       Start a Vault agent
  server      Start a Vault server
  status      Print seal and HA status
  unwrap      Unwrap a wrapped secret

Other commands:
  audit          Interact with audit devices
  auth           Interact with auth methods
  debug          Runs the debug command
  kv             Interact with Vault's Key-Value storage
  lease          Interact with leases
  namespace      Interact with namespaces
  operator       Perform operator-specific tasks
  path-help      Retrieve API help for paths
  plugin         Interact with Vault plugins and catalog
  policy         Interact with policies
  print          Prints runtime configurations
  secrets        Interact with secrets engines
  ssh            Initiate an SSH session
  token          Interact with tokens
```

## Conclusion
You now have an automated system for deploying Hashicorp Vault on DigitalOcean Droplets using Terraform and Packer. To start using Vault, you’ll need to initialize it and further configure it. For instructions on how to do that, visit the official docs.

For more tutorials using Terraform, check out our [Terraform content page](https://www.digitalocean.com/community/tags/terraform).


# DigitalOcean Terraform and Ansible Demo

This repository contains [Terraform](https://www.terraform.io/) and [Ansible](https://www.ansible.com/) configurations to launch and set up some basic infrastructure on DigitalOcean. As server deployments and development teams continue to get larger and more complex, the practice of defining infrastructure as version-controlled code has taken off. Tools such as Ansible and Terraform allow you to clearly define the servers you need (and firewalls, load balancers, etc.) and the configuration of the operating system and software on those servers.

This demo will create the following infrastructure using Terraform:

- Two 1 GB Droplets in the NYC3 datacenter running Ubuntu 20.04
- One DigitalOcean Load Balancer to route HTTP traffic to the Droplets
- One DigitalOcean Cloud Firewall to lock down communication between the Droplets and the outside world

We will then use Ansible to run the following tasks on both Droplets:

- Update all packages
- Install the DigitalOcean monitoring agent, to enable resource usage graphs in the Control Panel
- Install the Nginx web server software
- Install a demo `index.html` that shows Sammy and the Droplet's hostname


## Prerequisites

You will need the following software installed to complete this demo:

- **Git:** You'll use Git to download this repository to your computer. You can learn how to install Git on Linux, macOS, or Windows by reading our [Getting Started with Git](https://www.digitalocean.com/community/tutorials/contributing-to-open-source-getting-started-with-git) guide
- **Terraform:** Terraform will control your server and load balancer infrastructure. To install it locally, read the _Install Terraform_ section of [How To Use Terraform with DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-use-terraform-with-digitalocean#install-terraform)
- **Ansible:** Ansible is used to configure the servers after Terraform has created them. [The official Ansible documentation](https://docs.ansible.com/ansible/latest/intro_installation.html) has installation instructions for a variety of operating systems

**You will also need an SSH key set up on your local computer**, with the public key uploaded to the DigitalOcean Control Panel. You can find out how to do that using our tutorial [How To Use SSH Keys with DigitalOcean Droplets](https://www.digitalocean.com/community/tutorials/how-to-use-ssh-keys-with-digitalocean-droplets).

Finally, **you will need a personal access token for the DigitalOcean API**. You can find out more about the API and how to generate a token by reading [How To Use the DigitalOcean API v2](https://www.digitalocean.com/community/tutorials/how-to-use-the-digitalocean-api-v2)

When you have the software, an SSH key, and an API token, proceed to the first step.


## Step 1 — Clone the Repository and Configure

First, download the repository to your local computer using `git clone`. Make sure you're in the directory you'd like to download to, then enter the following command:

```java
git clone https://github.com/do-community/terraform-ansible-demo.git
```

Navigate to the resulting directory:

```java
cd terraform-ansible-demo
```

We need to update a few variables to let Terraform know about our keys and tokens. Terraform will look for variables in any `.tfvars` file. An example file is included in the repo. Copy the example file to to a new file, removing the `.example` extension:

```java
cp terraform.tfvars.example terraform.tfvars
```

Open the new file in your favorite text editor. You'll see the following:

```java
do_token = ""
ssh_fingerprint = ""
```

Fill in each variable:

- **do_token:** is your personal access token for the DigitalOcean API
- **ssh_fingerprint:** the DigitalOcean API refers to SSH keys using their _fingerprint_, which is a shorthand identifier based on the key itself.

  To get the fingerprint for your key, run the following command, being sure to update the path (currently `~/.ssh/id_rsa.pub`) to the key you're using with DigitalOcean, if necessary:

  ```java
  ssh-keygen -E md5 -lf ~/.ssh/id_rsa.pub | awk '{print $2}'
  ```

  The output will be similar to this:

  ```java
  MD5:ac:eb:de:c1:95:18:6f:d5:58:55:05:9c:51:d0:e8:e3
  ```

  **Copy everything _except_ the initial `MD5:`** and paste it into the variable.

Now we can initialize Terraform. This will download some information for the DigitalOcean Terraform _provider_, and check our configuration for errors.

```java
terraform init
```

You should get some output about initializing plugins. Now we're ready to provision the infrastructure and configure it.


## Step 2 — Run Terraform and Ansible

We can provision the infrastructure with the following command:

```java
terraform apply
```

Terraform will figure out the current state of your infrastructure, and what changes it needs to make to satisfy the configuration in `terraform.tf`. In this case, it should show that it's creating two Droplets, a load balancer, a firewall, and a _null_resource_ (this is used to create the `inventory` file for Ansible).

If all looks well, type `yes` to proceed.

Terraform will give frequent status updates as it launches infrastructure. Eventually, it will complete and you'll be returned to your command line prompt. Take note of the IP that Terraform outputs at the end:

```java
Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:

ip = 203.0.113.11
```

This is the IP of your new load balancer. If you navigate to it in your browser, you'll get an error: the Droplets aren't serving anything yet!

Let's fix that by running Ansible to finish setting up the servers:

```java
ansible-playbook -i inventory ansible.yml
```

Ansible will output some status information as it works through the tasks we've defined in `ansible.yml`. When it's done, the two Droplets will both be serving a unique web page that shows the hostname of the server.

Go back to your browser and enter the load balancer IP again. It may take a few moments to start working, as the load balancer needs to run some health checks before putting the Droplets back into its round-robin rotation. After a minute or so the demo web page with Sammy the shark will load:

![Demo web page with Sammy the shark and a hostname](https://assets.digitalocean.com/articles/tf-ansible-demo/demo-page.png)

If you refresh the page, you'll see the hostname toggle back and forth as the load balancer distributes the requests between both backend servers (some browsers cache more heavily than others, so you may have to hold `SHIFT` while refreshing to actually send a new request to the load balancer).

Take some time to browse around the DigitalOcean Control Panel to see what you've set up. Notice the two Droplets, `demo-01` and `demo-02` in your **Droplets** listing. Navigate to the **Networking** section and take a look at the `demo-lb` load balancer:

![DigitalOcean load balancer interface ](https://assets.digitalocean.com/articles/tf-ansible-demo/load-balancer.png)

In the **Firewalls** tab, you can investigate the `demo-firewall` entry. Notice how the Droplets are set up to only accept web traffic from the load balancer:

![DigitalOcean firewall rules interface](https://assets.digitalocean.com/articles/tf-ansible-demo/firewall.png)

When you're done exploring, you can destroy all of the demo infrastructure using Terraform:

```java
terraform destroy
```

This will delete everything we set up for the demo. Or, you could build upon this configuration to deploy your own web site or application! Read on for suggestions of further resources that might help.


## Conclusion

This demo was a quick intro into Terraform and Ansible. You are encouraged to take a look at the `terraform.tf` file to learn more about what we did with Terraform, and `ansible.yml` to see the tasks that Ansible performed. For more information on Ansible and Terraform, check out the following sources:

- [How To Use Terraform with DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-use-terraform-with-digitalocean#install-terraform)
- [How to Install and Configure Ansible on Ubuntu 16.04](https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-ansible-on-ubuntu-16-04)
- [The official Terraform documentation](https://www.terraform.io/docs/)
- [The official Ansible documentation](https://docs.ansible.com/ansible/latest/index.html)
- [The DigitalOcean API documentation](https://developers.digitalocean.com/documentation/v2/) can be useful when specifying DigitalOcean resources in Terraform
