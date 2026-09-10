from fastapi import FastAPI, HTTPException, Request
import redis
import os

app = FastAPI()

# Redis connection settings.
#
# Kubernetes will inject REDIS_HOST and REDIS_PORT through
# the redis-cm ConfigMap.
#
# Kubernetes will inject REDIS_PASSWORD through
# the redis-secret Secret.

REDIS_HOST = os.getenv("REDIS_HOST", "redis")
REDIS_PORT = int(os.getenv("REDIS_PORT", "6379"))
REDIS_PASSWORD = os.getenv("REDIS_PASSWORD")

# Redis client.
#
# At this stage, REDIS_PASSWORD is intentionally not passed
# into the Redis client because the assignment's Redis
# Deployment does not configure Redis authentication.
#
# The Secret is being used to demonstrate Kubernetes Secret
# injection into the FastAPI Pod.

r = redis.Redis(
    host=REDIS_HOST,
    port=REDIS_PORT
)

@app.middleware("http")
async def log_requests(request: Request, call_next):
    print(f"Incoming request path: {request.url.path}")

    response = await call_next(request)

    return response

@app.get("/")
def root():
    return{
        "message": "FastAPI is working"
    }

@app.post("/cache")
def store_value(key: str, value: str):
    r.set(key, value)

    return{
        "message": f"Stored key '{key}'"
    }

@app.get("/cache")
def get_value(key: str):
    value = r.get(key)

    if value is None:
        raise HTTPException(
            status_code=404,
            detail="Key not found"
        )
    return{
        "key": key,
        "value": value.decode()
    }

@app.get("/secret-test")
def show_secret():
    return{
        "password": os.getenv("REDIS_PASSWORD")
    }