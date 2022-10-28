## The Process

### Building your package

**WARNING:** *Before starting go through the links on the [reference page](https://wordops.github.io/nginx-build/reference/).*

**NOTE:** *This guide is for building the version 1.22.1 of Nginx. You might need to change the commands according to the latest stable version of Nginx.*

1. Start the container.

```bash
mkdir ~/nginx-build
cd ~/nginx-build
docker run --name=nginx-build -dit -v $PWD:/root/data virtubox/nginx-build bash
```

2. Copy the GPG keys(both public and private) to `~/nginx-build` and if you don't have one, you can check [here](https://wordops.github.io/nginx-build/GPG-keys-help/), how to create one.

3. Enter the container.

```bash
docker exec -it nginx-build bash
```

4. Import the your GPG keys.

```bash
cd /root/data/
gpg --import public.key
gpg --import --allow-secret-key-import private.key
```

5. Clone the repo.

```bash
git clone https://github.com/WordOps/nginx-build
cd nginx-build
```

6. Set **your name** as the Package Maintainer.

```bash
export DEBFULLNAME="WordOps"
```

7. Run the script with the _latest **stable** release_ and **your email id**.

```bash
bash ppa.sh wordops@example.com
```

At the end, the script will open your favorite editor to add content into the changelog.

```bash
nginx (1.22.1-1ppa~stable) jammy; urgency=medium

  * Update to Nginx 1.22.1 in response to HTTP/2 vulnerabilities

 -- Thomas SUCHON <thomas@virtubox.net>  Fri, 19 Oct 2022 01:03:00 +0530
```

This revision number of the build in bold has to be changed to build it
successfully.  (1.22.1-1ppa~stable) This will download the latest Nginx source, the modules from their respective
Github links, modify the changelog and create the whole directory structure at `~/PPA/nginx`

8. Go to the nginx directory (check the latest version)

```bash
cd ~/PPA/nginx/nginx-1.22.1
```

9. Start the packaging with the GPG keys that you have exported. If in doubt about GPGKEY, you can check [this page.](https://wordops.github.io/nginx-build/GPG-keys-help/)

```bash
debuild -S -sd -k97BAD476
```

This is the key ID for WordOps GPG key. You will be asked for a password. Get the password for the GPG key.

### Uploading the package to the repositories

#### Opensuse Build Service

10. Checkout the repository. If you don't have a repository, go to [Opensuse Build Service](https://build.opensuse.org), and create one

```bash
cd ~
osc co home:virtubox:WordOps
```

**Warning**: The repository name is case sensitive.

11. Remove the current files from the nginx repo.

```bash
cd home\:virtubox\:WordOps/nginx
osc rm *
```

12. The files that need to be uploaded will be generated in the `~/PPA/nginx`
directory. Only the files you already see [here](https://build.opensuse.org/package/show/home:virtubox:WordOps/nginx)
will be necessary.
Copy the files from `~/PPA/nginx` to `~/home:virtubox/nginx`.

```bash
rsync -avzP --exclude="modules" --exclude="nginx-1.22.1" ~/PPA/nginx/ ~/home:virtubox:WordOps/nginx/
```

13. Add the new files to the repo.

```bash
osc add *
```

14. Commit and push the changes.

```bash
osc ci -m "Revision message describing any changes"
```

#### LaunchPad PPA

For LauchPad PPA, nginx package name have to include the Ubuntu release you want to build. For this we will use the tool backportpackage to create each version of nginx package we want.

1. Go into the nginx directory

```bash
cd ~/PPA/nginx
```

2. Then use `backportpackage` on the .dsc file previously built for OpenSuse repository

```bash
backportpackage -r -w . -d bionic -d jammy -d focal -k97BAD476 nginx_1.22.1-1ppa~stable.dsc
```

Replace `-k97BAD476` with your GPG key ID.
It will build 3 nginx packages, for Ubuntu 18.04 (bionic), Ubuntu 20.04 (focal) and Ubuntu 22.04 (jammy).

3. Upload your package to LaunchPad PPA

```bash
dput ppa:virtubox/nginx nginx_1.22.1-1ppa~stable~ubuntu18.04.1_source.changes
dput ppa:virtubox/nginx nginx_1.22.1-1ppa~stable~ubuntu20.04.1_source.changes
dput ppa:virtubox/nginx nginx_1.22.1-1ppa~stable~ubuntu22.04.1_source.changes
```

You have to upload an indivual nginx package for each Ubuntu release you want to support.
