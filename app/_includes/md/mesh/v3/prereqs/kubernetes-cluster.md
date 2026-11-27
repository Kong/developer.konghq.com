The series runs each zone in its own [minikube](https://minikube.sigs.k8s.io/docs/) cluster, with the Docker driver.
The `zone2` cluster joins the Docker network of the `zone1` cluster, so start `zone1` with the following profile name:

```sh
minikube start -p mesh-zone --driver=docker
```
