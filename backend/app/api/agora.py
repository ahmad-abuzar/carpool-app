"""
Agora Token Generation API
Generates RTC tokens for secure audio/video calls
"""
from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field
from typing import Optional
import time
import hashlib
import hmac
import struct

router = APIRouter()


class AgoraTokenRequest(BaseModel):
    """Request to generate an Agora RTC token"""
    channel_name: str = Field(..., description="Channel name for the call")
    uid: int = Field(default=0, description="User ID (0 for auto-assign)")
    role: str = Field(default="publisher", description="Role: publisher or subscriber")
    expiration_seconds: int = Field(default=3600, description="Token expiry in seconds")


class AgoraTokenResponse(BaseModel):
    """Response with generated token"""
    token: str
    channel_name: str
    uid: int
    expiration_seconds: int


# ─── Agora Token Builder (built-in, no external dependency needed) ───

class AgoraRtcTokenBuilder:
    """
    Simplified Agora RTC token builder.
    Based on Agora's token generation algorithm.
    """

    ROLE_PUBLISHER = 1
    ROLE_SUBSCRIBER = 2

    @staticmethod
    def build_token(
        app_id: str,
        app_certificate: str,
        channel_name: str,
        uid: int,
        role: int,
        privilege_expired_ts: int
    ) -> str:
        """Build an Agora RTC token"""
        if not app_id or not app_certificate:
            raise ValueError("App ID and App Certificate are required")

        # Generate message
        ts = int(time.time())
        salt = int(time.time() * 1000) % 100000000

        # Build token content
        message = {
            'salt': salt,
            'ts': ts,
            'privileges': {
                1: privilege_expired_ts,  # kJoinChannel
                2: privilege_expired_ts if role == AgoraRtcTokenBuilder.ROLE_PUBLISHER else 0,  # kPublishAudioStream
                3: privilege_expired_ts if role == AgoraRtcTokenBuilder.ROLE_PUBLISHER else 0,  # kPublishVideoStream
            }
        }

        # Pack message
        content = AgoraRtcTokenBuilder._pack_content(message)

        # Generate signature
        sign_data = f"{app_id}{channel_name}{str(uid)}{content}".encode('utf-8')
        signature = hmac.new(
            app_certificate.encode('utf-8'),
            sign_data,
            hashlib.sha256
        ).hexdigest()

        # Encode token
        import base64
        version = "007"
        token_content = f"{version}{app_id}{signature}{content}"
        return base64.b64encode(token_content.encode('utf-8')).decode('utf-8')

    @staticmethod
    def _pack_content(message: dict) -> str:
        """Pack message content into a string"""
        import json
        return json.dumps(message, sort_keys=True)


# ─── Configuration (loaded from environment) ───

import os
from dotenv import load_dotenv

load_dotenv()

AGORA_APP_ID = os.getenv('AGORA_APP_ID', '')
AGORA_APP_CERTIFICATE = os.getenv('AGORA_APP_CERTIFICATE', '')


@router.post("/agora/token", response_model=AgoraTokenResponse)
async def generate_agora_token(request: AgoraTokenRequest):
    """
    Generate an Agora RTC token for audio/video calls

    **Request Body:**
    ```json
    {
        "channel_name": "call_user123_user456",
        "uid": 0,
        "role": "publisher",
        "expiration_seconds": 3600
    }
    ```

    **Response:**
    ```json
    {
        "token": "007eJxT...",
        "channel_name": "call_user123_user456",
        "uid": 0,
        "expiration_seconds": 3600
    }
    ```
    """
    try:
        if not AGORA_APP_ID:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Agora App ID not configured. Set AGORA_APP_ID in .env"
            )

        if not AGORA_APP_CERTIFICATE:
            # If no certificate, return a placeholder indicating 
            # the app is using App ID only mode (testing)
            return AgoraTokenResponse(
                token="",  # Empty token = App ID only mode
                channel_name=request.channel_name,
                uid=request.uid,
                expiration_seconds=request.expiration_seconds,
            )

        # Determine role
        role = (
            AgoraRtcTokenBuilder.ROLE_PUBLISHER
            if request.role == "publisher"
            else AgoraRtcTokenBuilder.ROLE_SUBSCRIBER
        )

        # Calculate expiration timestamp
        expiration_ts = int(time.time()) + request.expiration_seconds

        # Generate token
        token = AgoraRtcTokenBuilder.build_token(
            app_id=AGORA_APP_ID,
            app_certificate=AGORA_APP_CERTIFICATE,
            channel_name=request.channel_name,
            uid=request.uid,
            role=role,
            privilege_expired_ts=expiration_ts,
        )

        return AgoraTokenResponse(
            token=token,
            channel_name=request.channel_name,
            uid=request.uid,
            expiration_seconds=request.expiration_seconds,
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error generating Agora token: {str(e)}"
        )


@router.get("/agora/config")
async def get_agora_config():
    """
    Get Agora configuration (App ID only, no secrets)

    Useful for client-side initialization.
    """
    return {
        "app_id": AGORA_APP_ID,
        "token_required": bool(AGORA_APP_CERTIFICATE),
    }
