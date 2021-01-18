# Safe and Secure AWS S3 Bucket

Opinionated Terraform Module to create a secure by default S3 Bucket.

## Features

### Forces AES256 Encryption

All objects uploaded to the bucket by default must be AES256 encrypted. Enforced by the bucket
policy and the default object upload.

### Forces Bucket Owner Full Control

Bucket policy makes sure the ACLs are bucket owner full control

### Blocks Public Access