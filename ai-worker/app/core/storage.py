from pathlib import Path
from minio import Minio
from app.core.config import get_settings


class ObjectStorage:
    def __init__(self):
        self.settings = get_settings()
        self.client = Minio(
            self.settings.minio_endpoint,
            access_key=self.settings.minio_access_key,
            secret_key=self.settings.minio_secret_key,
            secure=self.settings.minio_secure,
        )
        if not self.client.bucket_exists(self.settings.minio_bucket):
            self.client.make_bucket(self.settings.minio_bucket)

    def download_file(self, object_key: str, dest: Path) -> Path:
        dest.parent.mkdir(parents=True, exist_ok=True)
        self.client.fget_object(self.settings.minio_bucket, object_key, str(dest))
        return dest

    def upload_file(self, src: Path, object_key: str, content_type: str | None = None) -> str:
        self.client.fput_object(
            self.settings.minio_bucket,
            object_key,
            str(src),
            content_type=content_type or "application/octet-stream",
        )
        return object_key

    def upload_bytes(self, data: bytes, object_key: str, content_type: str) -> str:
        from io import BytesIO

        self.client.put_object(
            self.settings.minio_bucket,
            object_key,
            BytesIO(data),
            length=len(data),
            content_type=content_type,
        )
        return object_key
