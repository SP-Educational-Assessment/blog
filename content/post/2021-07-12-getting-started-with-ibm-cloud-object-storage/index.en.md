---
title: Getting Started with IBM Cloud Object Storage
author: James Page
date: '2021-07-12'
slug: getting-started-with-ibm-cloud-object-storage
tags:
  - data
  - s3
  - python
lastmod: '2021-07-12T22:32:49+01:00'
featured: no
authors: [ 'james-page' ]
series: [ 'Cloud Object Storage' ]
image:
  caption: ''
  focal_point: ''
  preview_only: no
---

[IBM Cloud Storage (COS)](https://www.ibm.com/cloud/object-storage) is a cloud object storage system, similar to Amazon S3 or Azure Blob Storage. You create 'buckets' in the cloud storage service, upload files to those buckets, and provide access via policies.

In these next couple of posts I'll show how to use IBM Cloud Storage for a data science project, allowing you to share data with an IBM Watson service (for instance), or for colleagues.

Data that you store with Cloud Storage is encrypted and spread across multiple geographic locations. It's a secure and resilient approach to the problem of storing large data sets, like CSV or Excel files.

You can access IBM Cloud Storage through the cloud console: <https://cloud.ibm.com/resources>, under the **Storage** section. Documentation can be found here: <https://cloud.ibm.com/docs/cloud-object-storage>.

In this post I'll explain how to:

* Upload a file to COS
* Allow secure access with an Access token

I'll provide a Python code example showing how to access files in Object Storage programmatically.

Later posts will show how to:

* Allow secure access with an HMAC token
* Allow public access to everyone
* Access files from an [IBM Cloud Pak for Data](https://www.ibm.com/support/producthub/icpdata/resources) app

If you don't already have an IBM Cloud account you can sign up for one [here](https://cloud.ibm.com/registration). Once you've registered your account you can add an IBM Cloud Object Storage service. The Lite plan gives you an amount of storage you can use for free, and is enough to try out the examples shown in this post.

To create a new Object Storage service navigate to the Catalog in the IBM Cloud console and search for **Object Storage**.

![Upload to Storage Bucket](images/ibm-cloud-catalog.png)

First though I'll take a little detour to explain how *authentication* works with COS.

## Authentication

Access to objects stored in Cloud Storage is via *IBM Cloud Identity and Access Management (IAM)*. You can provide access to a bucket for people in your organisation and outside, and you can also provide access for services, such as third-party APIs or data access tools.

The way this works is you must first create an *API key*. You can think of this as the secret that your service will make use of in order to acquire a short-lived *API token* that can be used to actually access the bucket and the objects in it.

You can create API Keys using the IAM service. However for access to Cloud Storage objects its easier to do this from the IBM Cloud Storage area of the IBM Cloud console.

### API Keys

The API Key is a secret that you generate and then use for your own access and also for generating tokens that others can use. It goes without saying that this is a sensitive piece of information, and you should be careful not to share it (so make sure you don't check it into your source control). If you think your key has been compromised and someone else has access to it you should delete it from IBM Cloud and create a new one.

Say that you have a script that will read and write files to COS. You'll need to create a *service credential* for the script, as well as the *API key* (secret)* that the script will use to generate API tokens.

#### Service Credentials

First you'll create a *service credential*, otherwise known as a *service ID*, which will identify your service or application (think of it as being similar to how a user ID identifies a person). These service IDs allow access to your IBM Cloud services by applications hosted either inside or outside the IBM Cloud. For example, say we have a project that will analyse student data, we could create a service ID for the data access component of this project and call it **StudentDataAccess**. Maybe the project consists of a set of Jupyter notebooks and associated scripts, or maybe it runs as a Docker container. Anyway, its worth saying that it may be running in the IBM Cloud, in another cloud provider such as AWS or GCP, or on a local network with access to IBM Cloud. Wherever it is running it will need to know the details of the service credentials you create for it. You can view all the service credentials you have on the IBM CLoud from <https://cloud.ibm.com/iam/serviceids>.

To create a new one from the Cloud Object Storage part of the console, go to the Service credentials menu for your storage service. Say you have a project that will store and manage student data, you could create a service ID called **StudentDataAccess**. You can download or copy to the clipboard your service credentials (including the API key), which will look like this:

```json
{
    "apikey": "qzUeTREDKw0PSQsh0buted_N_iRJeVWzdIOrotkJpSIC",
    "endpoints": "https://control.cloud-object-storage.cloud.ibm.com/v2/endpoints",
    "iam_apikey_description": "Auto-generated for key 462e74e1-488a-4470-b454-86a751b4dcc9",
    "iam_apikey_name": "COS-Access",
    "iam_role_crn": "crn:v1:bluemix:public:cloud-object-storage::::serviceRole:ContentReader",
    "iam_serviceid_crn": "crn:v1:bluemix:public:iam-identity::a/8186f85d5f36d73d0caeb990c044a71f::serviceid:ServiceId-6b0b2224-b003-4b21-bd4b-ddcac2683635",
    "resource_instance_id": "crn:v1:bluemix:public:cloud-object-storage:global:a/8186f85d5f36d73d0caeb990c044a71f:5b93d3fc-c2ad-4fdd-9444-85e941c3603f::"
}
```

The `apikey`, `endpoints` and `resource_instance_id` propeties will be used later on.

### Access Tokens

Once you have an API key you can use it to generate access tokens that can then be used to actually make requests to Cloud Storage. This is a temporary "bearer token" which can then be included in the HTTP header for requests that you make for objects in cloud storage.

#### Example Token Requests

You use a REST API call to acquire a token. See [here](https://cloud.ibm.com/docs/cloud-object-storage?topic=cloud-object-storage-curl#curl-token) for the documentation. Here's an example API request:

```bash
curl -X POST "https://iam.cloud.ibm.com/oidc/token" \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode "apikey={api-key}" \
    --data-urlencode "response_type=cloud_iam" \
    --data-urlencode "grant_type=urn:ibm:params:oauth:grant-type:apikey" 
```

Replace `{api-key}` with your actual API key. The response data will be in JSON format and include an `access_token` value, like this:

```json
{
    "access_token": "eyJraWQiO...TnM24r0a_aSng",
    "refresh_token": "not_supported",
    "token_type": "Bearer",
    "expires_in": 3600,
    "expiration": 1621627661,
    "scope": "ibm openid"
}
```

The actual `access_token` value will be a *very* long character string, I'm just showing an elided version in the above example. This access token is what you want to include as the `Authorization: Bearer` header value when you make an object request. Note that the token expires in one hour (3600 seconds).

Once you have a bearer token like this you can then use it to actually download a file. To do this first create a bucket and upload a file that you can practice with.

## Uploading a File to Cloud Object Storage

Before creating a bucket you need to create an Object Storage service if you haven't already. You can create as many instances of these storage services as you want, and each can hold a number of buckets, with each bucket containing many files. In general, you'll want to have at least one storage service per resource group.

Once you've created a storage service you can create a bucket and upload a file to it. For example, here we've uploaded a data file `student-data.csv` to a bucket called `studentdata` in the **TestData** storage service (which happens to be in the **Default** resource group).

![Upload to Storage Bucket](images/bucket-object.png)

## Downloading a File with an Access Token

It is possible to download directly from the IBM Cloud console, but I'd like to show you how to download the file programmatically using the access token you generated previously.

First of all, get a list of objects in the bucket you created; you do this by copying the value of the `access_token` to the `Authorization: Bearer` header, like this:

```bash
curl -X GET "https://s3.eu.cloud-object-storage.appdomain.cloud/studentdata" \
    -H "Authorization: Bearer eyJraWQiO...TnM24r0a_aSng"
```

Assuming your token is a valid one you'll be able to list the objects in the bucket. The list will be in an XML format. You can also use the token to download the file by appending the object name to the bucket name:

```bash
curl -X GET "https://s3.eu.cloud-object-storage.appdomain.cloud/studentdata/student-data.csv" \
    -H "Authorization: Bearer eyJraWQiO...TnM24r0a_aSng"
```

### Python Download Example

This next section does the same but from a Python script. In this article I'll show how to use the **IBM COS SDK for Python** (aka [`ibm_boto3`](https://pypi.org/project/ibm-cos-sdk/1.0.2/)). It's a fork of the [`boto3`](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html) library commonly used for access to AWS resources. This is the most straightforward way that I've found to deal with IBM Cloud Object Storage from a Python program.

Here's an example of calling the `resource` function from `ibm_boto3` to load a file from a bucket into a data frame:

```python
import ibm_boto3
from ibm_botocore.client import Config
import requests, io, json
import pandas as pd

with open('cos-credentials.json', 'r') as credentialsfile:
   data = credentialsfile.read()

credentials = json.loads(data)
apikey = credentials['apikey']
crn = credentials['resource_instance_id']

response = requests.get(credentials['endpoints'])
endpoints = response.json()
cosEndpoint = 'https://' + endpoints['service-endpoints']['cross-region']['eu']['public']['eu-geo']

cos = ibm_boto3.resource("s3",
                         ibm_service_instance_id=crn,
                         endpoint_url=cosEndpoint,
                         ibm_api_key_id=apikey,
                         config=Config(signature_version="oauth"))
object = cos.Object('studentdata', 'student-data.csv')

csvFile = object.get()
csvStream = io.StringIO(csvFile["Body"].read().decode('utf-8'))
df = pd.read_csv(csvStream)
csvStream.close()
```

I'll go through what's happening here.

First we import the `ibm_boto3` and `pandas` libraries; you can pip-install them like this:

```bash
pip install ibm-cos-sdk pandas
```

In the Python script you import the necessary libraries including `ibm_boto3` and `pandas` as follows:

```python
import ibm_boto3
from ibm_botocore.client import Config
import requests, io, json
import pandas as pd
```

The first bit of code will get hold of the necessary service credentials (including the API key) from a local file called `cos-credentials.json`; you could just as easily use environment variables, or better still read it in from a secret manager. Because the API key is a secret you should make sure that you *don't* store it in the code itself.

```python
with open('cos-credentials.json', 'r') as credentialsfile:
   credentials = json.loads(credentialsfile.read())

apikey = credentials['apikey']
crn = credentials['resource_instance_id']
```

For the storage endpoint we can either use a pre-defined one such as `s3.eu.cloud-object-storage.appdomain.cloud` (read from an environment variable or simply a constant in the code), or query the IBM Cloud Object Storage service. This latter approach is what we do in this example:

```python
response = requests.get(credentials['endpoints'])
endpoints = response.json()
cosEndpointUrl = 'https://' + endpoints['service-endpoints']['cross-region']['eu']['public']['eu-geo']
```

Remember to make sure you prepend the `https://` scheme to the endpoint before using it.

Now we have the service credentials we can initialise a COS object by calling `ibm_boto3.resource` (passing the key along with the CRN and the endpoint URL):

```python
cos = ibm_boto3.resource("s3",
                         ibm_service_instance_id=crn,
                         endpoint_url=cosEndpointUrl,
                         ibm_api_key_id=apikey,
                         config=Config(signature_version="oauth"))
object = cos.Object('studentdata', 'student-data.csv')
```

Finally we can download the CSV file and pass it to the Pandas function `read_csv` (as a string buffer):

```python
csvFile = object.get()
csvStream = io.StringIO(csvFile["Body"].read().decode('utf-8'))
df = pd.read_csv(csvStream)
csvStream.close()
```

The CSV data is now ready to be analysed in your Python program.

## Summary

I showed you in this post how to securely access a file from IBM Cloud Storage using an access token, both with a simple `curl` request, and also using the `ibm_boto3` Python library. In the next post I'll explain how to make similar requests but using an HMAC token. I'll cover the differences between the access tokens used in this post and HMAC tokens, and also show examples of using them from a R program.

