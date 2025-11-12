from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request

class LanguageMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        # Get language from Accept-Language header
        accept_language = request.headers.get('accept-language', 'en')
        
        # Store language in request state
        request.state.language = accept_language.split(',')[0].split('-')[0]
        
        response = await call_next(request)
        return response