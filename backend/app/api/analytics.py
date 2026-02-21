"""
Analytics API endpoints
Provides ride statistics, earnings, and popular routes
"""
from fastapi import APIRouter, HTTPException, status
from app.services.firebase_service import firebase_service

router = APIRouter()


@router.get("/analytics/rides/{user_id}")
async def get_ride_statistics(user_id: str):
    """
    Get ride statistics for a user

    Returns total rides, rides as driver, rides as passenger, and completion rate.
    """
    try:
        user_data = await firebase_service.get_user_profile(user_id)

        if not user_data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"User {user_id} not found"
            )

        # Get ride history
        rides = await firebase_service.get_ride_history(user_id)

        # Calculate stats
        total_rides = len(rides)
        rides_as_driver = sum(1 for r in rides if r.get('role') == 'driver')
        rides_as_passenger = sum(1 for r in rides if r.get('role') == 'passenger')
        completed_rides = sum(1 for r in rides if r.get('status') == 'completed')
        cancelled_rides = sum(1 for r in rides if r.get('status') == 'cancelled')

        completion_rate = (
            (completed_rides / total_rides * 100) if total_rides > 0 else 100.0
        )

        return {
            "user_id": user_id,
            "total_rides": total_rides,
            "rides_as_driver": rides_as_driver,
            "rides_as_passenger": rides_as_passenger,
            "completed_rides": completed_rides,
            "cancelled_rides": cancelled_rides,
            "completion_rate": round(completion_rate, 1),
            "rating": user_data.get('rating', 0.0),
            "total_ratings": user_data.get('totalRatings', 0),
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error fetching ride statistics: {str(e)}"
        )


@router.get("/analytics/earnings/{user_id}")
async def get_earnings(user_id: str):
    """
    Get earning statistics for a driver

    Returns total earnings, monthly breakdown, and average per ride.
    """
    try:
        # Fetch payments where user is the receiver (driver)
        db = firebase_service.db
        payments_ref = db.collection('payments')
        query = payments_ref.where('receiverId', '==', user_id).where(
            'status', '==', 'completed'
        )

        docs = query.stream()
        payments = [doc.to_dict() for doc in docs]

        total_earnings = sum(p.get('amount', 0) for p in payments)
        total_rides_paid = len(payments)
        average_per_ride = (
            total_earnings / total_rides_paid if total_rides_paid > 0 else 0.0
        )

        # Monthly breakdown (last 6 months)
        from datetime import datetime, timedelta
        monthly = {}
        for payment in payments:
            ts = payment.get('timestamp')
            if ts:
                if hasattr(ts, 'timestamp'):
                    dt = datetime.fromtimestamp(ts.timestamp())
                else:
                    dt = datetime.now()
                month_key = dt.strftime('%Y-%m')
                monthly[month_key] = monthly.get(month_key, 0) + payment.get('amount', 0)

        return {
            "user_id": user_id,
            "total_earnings": round(total_earnings, 2),
            "total_rides_paid": total_rides_paid,
            "average_per_ride": round(average_per_ride, 2),
            "monthly_breakdown": monthly,
        }

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error fetching earnings: {str(e)}"
        )


@router.get("/analytics/popular-routes")
async def get_popular_routes(limit: int = 10):
    """
    Get popular routes based on ride history

    Returns most frequently used origin-destination pairs.
    """
    try:
        db = firebase_service.db
        rides_ref = db.collection('rides')
        query = rides_ref.order_by('departureTime', direction='DESCENDING').limit(500)

        docs = query.stream()
        rides = [doc.to_dict() for doc in docs]

        # Count route frequencies
        route_counts = {}
        for ride in rides:
            origin = ride.get('origin', {}).get('address', 'Unknown')
            destination = ride.get('destination', {}).get('address', 'Unknown')
            route_key = f"{origin} → {destination}"
            route_counts[route_key] = route_counts.get(route_key, 0) + 1

        # Sort by frequency
        sorted_routes = sorted(
            route_counts.items(), key=lambda x: x[1], reverse=True
        )[:limit]

        return {
            "total_routes_analyzed": len(rides),
            "popular_routes": [
                {
                    "route": route,
                    "trip_count": count,
                    "rank": idx + 1,
                }
                for idx, (route, count) in enumerate(sorted_routes)
            ]
        }

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error fetching popular routes: {str(e)}"
        )
