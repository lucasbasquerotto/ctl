# ansible-manager

This repository allows to manage several non-related repositories containing a file with environment variables.

It runs ansible in a main repository (that has all the logic to create instances, deploy containers and so on) and pass the environment variables to it.

This way, the logic in the main repository can be reused by different use cases.

The repository is an example of how to setup your own manager repository. The variables you should change to adapt to your use case are in `vars/main.yml`.

## 1) Create an instance and install ansible in it

## 2) Define the main repository that contains the logic you will use

This example uses https://github.com/lucasbasquerotto/ansible-docker.git as the main repository.

## 3) Define the repositories that contains the environment variables

This example uses https://github.com/lucasbasquerotto/ansible-env-demo.git as each client repository, each file refering to a different setup (in a real use case, each client repository could be in a separate repository).

Each of these repositories may contain variables to create instances and deploy containers to deploy something like a discourse website, a blog and so on. 

You can specify the platform, if it will be deployed in one or mor machines and so on.
