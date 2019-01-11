# AWS Environment Manager Script (WIP)

## Purpose
A BASH script to switch (set/unset) Environment Variables related to AWS CLI and Test Frameworks such as Test Kitchen.
Instead of hard coding profile information in say Test Kitchen, simply call Environment Variables that can be switched on the fly as needed to test multiple AWS Accounts / Profiles.

Project started as a Ruby script, but I quickly found out that Ruby can not set persistent Shell Environment Variables.

## Usage
### Create Folder Structure
The folder structure is an easy way to keep the configs organized.
```yaml
region:
  client:
    awsaccount:
      environment:
        project.yml
```

##### Example
```mkdir -p $HOME/.aem/us-west-2/client1/awsaccount1/dev```

### Create Settings YAML
```yaml
aws_ssh_key_id: uswest2_account1_webapp1_qa
aws_ssh_key_path: $HOME/.ssh/uswest2_account1_webapp1_qa.pem
aws_vpc_id: vpc-00000000
aws_iam_instance_profile: webapp1-qa
aws_security_groups:
  - sg-00000000
  - sg-00000000
  - sg-00000000
aws_subnets_public:
  - subnet-00000000
aws_subnets_private:
  - subnet-00000000
```


```
Usage: aem.rb -c examples/us-west-2/client1/awsaccount1/dev/webapp1.yml [OPTIONS]

Options:
    -c, --config FULLNAME            (Required) Full Path to YAML Account Config
    -d, --debug                      (Flag) Enable Debug Logging
    -h, --help                       (Flag) Show this message
    -v, --version                    (Flag) Output Script Version
```

## Examples
* ```./aem.rb -c account.yml -r us-west-2 -p account1 -e dev -j webapp```

### Symlink
To make it quick to call from bash_profile etc. you can create a symlink to the ruby script.
```bash
 if [ ! -h "/usr/local/bin/aem" ]; then
   ln -s "/path/to/clone/aws_env_manager/aem.sh" /usr/local/bin/aem
 fi
```
