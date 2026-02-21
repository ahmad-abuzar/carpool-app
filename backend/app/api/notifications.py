"""
Notifications API endpoints
Handles notification creation and retrieval via Firestore
"""
from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from app.services.firebase_service import firebase_service

router = APIRouter()


class NotificationRequest(BaseModel):
    """Request to create a notification"""
    user_id: str = Field(..., description="Target user ID")
    type: str = Field(..., description="Notification type (e.g., bookingConfirmed, rideStarting)")
    title: str = Field(..., description="Notification title")
    message: str = Field(..., description="Notification message body")
    ride_id: Optional[str] = Field(default=None, description="Related ride ID")
    action_url: Optional[str] = Field(default=None, description="Action URL")


class NotificationResponse(BaseModel):
    """Individual notification"""
    id: str
    user_id: str
    type: str
    title: str
    message: str
    timestamp: str
    read: bool
    ride_id: Optional[str] = None
    action_url: Optional[str] = None


@router.post("/notifications/send", status_code=status.HTTP_201_CREATED)
async def send_notification(request: NotificationRequest):
    """
    Create and send a notification to a user

    **Request Body:**
    ```json
    {
        "user_id": "user123",
        "type": "bookingConfirmed",
        "title": "Booking Confirmed!",
        "message": "Your ride from Gulberg to DHA has been confirmed.",
        "ride_id": "ride456"
    }
    ```
    """
    try:
        db = firebase_service.db
        notification_data = {
            'userId': request.user_id,
            'type': request.type,
            'title': request.title,
            'message': request.message,
            'timestamp': datetime.utcnow(),
            'read': False,
            'rideId': request.ride_id,
            'actionUrl': request.action_url,
        }

        doc_ref = db.collection('notifications').add(notification_data)
        notification_id = doc_ref[1].id

        return {
            "success": True,
            "notification_id": notification_id,
            "message": "Notification sent successfully",
        }

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error sending notification: {str(e)}"
        )


@router.get("/notifications/{user_id}")
async def get_notifications(user_id: str, limit: int = 50, unread_only: bool = False):
    """
    Get notifications for a user

    **Parameters:**
    - user_id: User ID
    - limit: Max notifications to return (default: 50)
    - unread_only: If true, only return unread notifications
    """
    try:
        db = firebase_service.db
        query = db.collection('notifications').where('userId', '==', user_id)

        if unread_only:
            query = query.where('read', '==', False)

        query = query.order_by('timestamp', direction='DESCENDING').limit(limit)

        docs = query.stream()
        notifications = []

        for doc in docs:
            data = doc.to_dict()
            ts = data.get('timestamp')
            timestamp_str = ''
            if ts:
                if hasattr(ts, 'isoformat'):
                    timestamp_str = ts.isoformat()
                elif hasattr(ts, 'timestamp'):
                    timestamp_str = datetime.fromtimestamp(ts.timestamp()).isoformat()

            notifications.append({
                'id': doc.id,
                'user_id': data.get('userId', ''),
                'type': data.get('type', ''),
                'title': data.get('title', ''),
                'message': data.get('message', ''),
                'timestamp': timestamp_str,
                'read': data.get('read', False),
                'ride_id': data.get('rideId'),
                'action_url': data.get('actionUrl'),
            })

        return {
            "user_id": user_id,
            "total": len(notifications),
            "notifications": notifications,
        }

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error fetching notifications: {str(e)}"
        )


@router.put("/notifications/{notification_id}/read")
async def mark_notification_read(notification_id: str):
    """
    Mark a notification as read
    """
    try:
        db = firebase_service.db
        doc_ref = db.collection('notifications').document(notification_id)

        doc = doc_ref.get()
        if not doc.exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Notification {notification_id} not found"
            )

        doc_ref.update({'read': True})

        return {
            "success": True,
            "message": "Notification marked as read",
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error marking notification as read: {str(e)}"
        )


@router.put("/notifications/{user_id}/read-all")
async def mark_all_read(user_id: str):
    """
    Mark all notifications as read for a user
    """
    try:
        db = firebase_service.db
        query = db.collection('notifications').where(
            'userId', '==', user_id
        ).where('read', '==', False)

        docs = query.stream()
        batch = db.batch()
        count = 0

        for doc in docs:
            batch.update(doc.reference, {'read': True})
            count += 1

        if count > 0:
            batch.commit()

        return {
            "success": True,
            "message": f"{count} notifications marked as read",
            "count": count,
        }

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error marking all as read: {str(e)}"
        )


@router.delete("/notifications/{notification_id}")
async def delete_notification(notification_id: str):
    """
    Delete a notification
    """
    try:
        db = firebase_service.db
        doc_ref = db.collection('notifications').document(notification_id)

        doc = doc_ref.get()
        if not doc.exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Notification {notification_id} not found"
            )

        doc_ref.delete()

        return {
            "success": True,
            "message": "Notification deleted",
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error deleting notification: {str(e)}"
        )
