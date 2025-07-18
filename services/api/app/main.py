from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Import routers
from app.api.v1.auth import router as auth_router
from app.api.v1.products import router as products_router
from app.api.v1.cart import router as cart_router
from app.api.v1.orders import router as orders_router
from app.api.v1.payments import router as payments_router
from app.api.v1.drivers import router as drivers_router
from app.api.v1.monitoring import router as monitoring_router

# Import monitoring
from app.core.monitoring import MonitoringMiddleware, monitoring_service

app = FastAPI(
    title="Dayliz API",
    description="API for Dayliz - Q-commerce Grocery Delivery App",
    version="0.1.0",
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # For production, replace with specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Add monitoring middleware
app.add_middleware(MonitoringMiddleware)

# Include routers
app.include_router(auth_router, prefix="/api/v1/auth", tags=["Authentication"])
app.include_router(products_router, prefix="/api/v1/products", tags=["Products"])
app.include_router(cart_router, prefix="/api/v1/cart", tags=["Cart"])
app.include_router(orders_router, prefix="/api/v1/orders", tags=["Orders"])
app.include_router(payments_router, prefix="/api/v1/payments", tags=["Payments"])
app.include_router(drivers_router, prefix="/api/v1/drivers", tags=["Drivers"])
app.include_router(monitoring_router, prefix="/api/v1/monitoring", tags=["Monitoring"])

@app.get("/")
async def root():
    return {"message": "Welcome to Dayliz API! Visit /docs for API documentation."}

@app.get("/health")
async def health_check():
    """Health check endpoint for UPI payment backend"""
    return {
        "status": "healthy",
        "message": "Dayliz UPI Payment API is running",
        "version": "1.0.0",
        "features": {
            "upi_payment_support": True,
            "razorpay_integration": True,
            "payment_retry": True,
            "payment_timeout": True
        }
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True) 