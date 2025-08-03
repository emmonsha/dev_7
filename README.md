# The basics of container orchestration

The use of Docker Compose and Docker Swarm tools to run containers together and orchestrate them in a simple way.

💡 [Tap here](https://new.oprosso.net/p/4cb31ec3f47a4596bc758ea1861fb624) **to leave your feedback on the project**. It's anonymous and will help our team make your educational experience better. We recommend completing the survey immediately after the project.

## Contents

1. [Chapter I](#chapter-i)
2. [Chapter II](#chapter-ii) \
   2.1. [Running multiple Docker containers using Docker Compose](#part-1-running-multiple-docker-containers-using-docker-compose-docker-compose) \
   2.2. [Creating virtual machines](#part-2-creating-virtual-machines) \
   2.3. [Creating a simple Docker Swarm](#part-3-creating-a-simple-docker-swarm)

## Chapter I

As you already know, **Docker** is a platform for building, running, and *delivering* applications, designed to run software almost regardless of the machine on which it will physically run. This is achieved by *containerizing* the software, which means placing the executable code in a separate environment called a *container* containing all the necessary dependencies and, if the container image is well composed, nothing else. 

However, the problem with dependencies is more serious than you might think. It's not just missing files or library versions, but also language versions and environment variable values, which can significantly affect the performance of the software, if not break it completely. The container guarantees *the same* execution of the containerized software on any machine, because it has everything needed for consistent operation. This is especially useful for web services that require frequent updates and deployment on different servers. 

Usually, a serious application does not consist of a single program, i.e. it does not have a monolithic structure, but a microservice one. Although each service can technically be deployed in a same container, this is not in line with SOLID principles or clean architecture in general. For example, this approach makes it practically impossible or significantly more difficult to deploy a new version of a separate microservice. You need to remember the basic rule of containerization: **"1 microservice — 1 container"**. 

Now that the rule about distributing microservices to containers has been defined, it is worth recalling another tool — **Docker Compose**, which allows you to run several containers together. **Docker Compose** not only allows you to run multiple Docker containers simultaneously, but also provides the ability to define their interaction, which is a necessary condition for deploying a microservice application.

However, **Docker Compose** alone allows you to run containers on only one machine. In reality, microservices applications are distributed on different machines: real or virtual, it does not matter. Usually, of course, these turn out to be virtual machines, but not necessarily all the virtual machines used by the same software are on the same real machine. Often this is not even the case. This is where **Docker Swarm** comes in. In general, the phrase **Docker Swarm** means both a group of machines combined into one *cluster*, with docker containers running on them linked together, and a tool which combines the machines into such a *cluster*. A *cluster* is a combination of machines or *nodes* into a single network with the load distributed over these nodes in the form of applications executed in containers. Special programs called orchestrators are responsible for running and curating such a cluster. **Docker Swarm** is just one of them. **Docker Swarm** is a relatively simple and easy to learn orchestrator with all the basic tools.

Finally, where do we get the machines that will be used as the basis for cluster nodes? The answer: virtualization. One of the most popular and simple tools for creating virtual machines is **Vagrant**. **Vagrant** allows you to quickly, with just a couple of commands, create multiple small virtual machines.

## Chapter II

The result of the work must be a report with detailed descriptions of the implementation of each of the points with screenshots. The report is prepared as a markdown file in the `src` directory named `REPORT.MD`.

## Part 1. Running multiple docker containers using Docker Compose

It is worth recalling how Docker Compose works! First, let's try to run the microservice application from the `src` folder so that the Postman tests are successful.

### Task

1) Write a Dockerfile for each individual microservice. The necessary dependencies are described in the materials. Write the size of the built images of any service in the report in different ways.

2) Write a Docker Compose file that correctly interacts with services. Forward the ports to access gateway and session services from the local machine. Help with the Docker Compose can be found in the materials.

3) Build and deploy a web service using a Docker Compose file written on the local machine.

4) Run the tests that you have prepared using Postman and ensure that they are all successful. Instructions on how to run tests can be found in materials. Record the test results in a report. 

## Part 2. Creating virtual machines

It's time to prepare the base for future cluster nodes. Let's create a virtual machine.

### Task

1) Install and initialize Vagrant in the root of your project. Create a Vagrantfile for one virtual machine. Move the source code for the web service into the working directory of the virtual machine. For help with Vagrant, check the materials. 

2) Use the console to enter the virtual machine to make sure the source code has been copied. Stop and delete the virtual machine when you're done. 

## Part 3. Creating a simple Docker Swarm

Now it's time to create your first Docker Swarm!

### Task

1) Modify the Vagrantfile to create three virtual machines: manager01, worker01 and worker02, and write shell scripts to install Docker inside each machine, initialize and connect them to Docker Swarm. Help on Docker Swarm can be found in the materials.

2) Load the built images on the Docker Hub and modify the Docker Compose file to load these images.

3) Run virtual machines, move the Docker Compose file to manager, and run the service stack with the Docker Composed file you created.

4) Configure an Nginx-based proxy for accessing the gateway and session services via the overlay network, making the gateway and sessions services themselves unavailable directly.

5) Run prepared tests using Postman and ensure they all are successful. Record the results in a report. 

6) Using Docker commands, display the distribution of containers across nodes in the cluster in the report.

7) Install a separate Portainer stack inside the cluster. Show the visualization of the distribution of workloads across nodes using Portainer in the report. 
# dev_7
