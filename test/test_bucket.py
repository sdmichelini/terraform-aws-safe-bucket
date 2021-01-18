import boto3
import random
import string
import subprocess
import time
import unittest

TF_DIR = "../example"
TEST_FILE = "./resources/example.txt"
BUCKET_SUFFIX = ''.join(random.choices(string.ascii_uppercase + string.digits, k=6)).lower()
BUCKET = f"integration-{BUCKET_SUFFIX}"


class TestSafeBucket(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        subprocess.check_call(['terraform', 'init'], cwd=TF_DIR)

        # will fail if already exists
        subprocess.call(['terraform', 'workspace', 'new', 'test'], cwd=TF_DIR)
        subprocess.check_call(['terraform', 'workspace', 'select', 'test'], cwd=TF_DIR)
        subprocess.check_call(['terraform', 'apply', '-var', f'name={BUCKET}', '-auto-approve'], cwd=TF_DIR)

    @classmethod
    def tearDownClass(cls):
        print("tearing down")
        retry_count = 0
        succeeded = False
        while not succeeded and retry_count < 6:
            try:
                subprocess.check_call(['terraform', 'destroy', '-var', f'name={BUCKET}', '-auto-approve'], cwd=TF_DIR)
                succeeded = True
            except:
                retry_count = retry_count + 1
                print("WARNING - terraform destroy failed - retrying in 30 more seconds - tried %d times" % retry_count)
                time.sleep(30)
        if not succeeded:
            raise Exception("Could not tear down terraform")

    def test_no_acl_block(self):
        bucket = self.get_bucket_name()
        s3 = boto3.client('s3')

        with self.assertRaises(boto3.exceptions.S3UploadFailedError):
            s3.upload_file(TEST_FILE, bucket, "fail.txt")

    def test_public_read_acl_block(self):
        bucket = self.get_bucket_name()
        s3 = boto3.client('s3')

        with self.assertRaises(boto3.exceptions.S3UploadFailedError):
            s3.upload_file(TEST_FILE, bucket, "fail.txt", ExtraArgs={'ACL': 'public-read'})

    def test_upload_succeeds_with_full_control(self):
        bucket = self.get_bucket_name()
        s3 = boto3.client('s3')

        s3.upload_file(TEST_FILE, bucket, "succeed.txt", ExtraArgs={'ACL': "bucket-owner-full-control"})

        s3_object = boto3.resource('s3').Object(bucket, "succeed.txt")

        self.assertEqual(s3_object.server_side_encryption, "AES256")

    @staticmethod
    def get_bucket_name():
        output = subprocess.check_output(["terraform", "output", "-raw", "bucket"], cwd=TF_DIR).strip()
        return output.decode("utf-8")


if __name__ == '__main__':
    unittest.main()
