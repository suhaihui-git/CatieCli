"""
简单内存缓存，用于减少数据库查询
不需要 Redis，适合中小型部署
"""

import time
from typing import Any, Optional
from functools import wraps

class SimpleCache:
    """简单的内存缓存"""
    
    def __init__(self):
        self._cache = {}
        self._expires = {}
    
    def get(self, key: str) -> Optional[Any]:
        """获取缓存值"""
        if key not in self._cache:
            return None
        if key in self._expires and time.time() > self._expires[key]:
            del self._cache[key]
            del self._expires[key]
            return None
        return self._cache[key]
    
    def set(self, key: str, value: Any, ttl: int = 60):
        """设置缓存值，ttl 为过期时间（秒）"""
        self._cache[key] = value
        self._expires[key] = time.time() + ttl
    
    def delete(self, key: str):
        """删除缓存"""
        self._cache.pop(key, None)
        self._expires.pop(key, None)
    
    def clear(self):
        """清空所有缓存"""
        self._cache.clear()
        self._expires.clear()
    
    def clear_prefix(self, prefix: str):
        """清除指定前缀的缓存"""
        keys_to_delete = [k for k in self._cache if k.startswith(prefix)]
        for key in keys_to_delete:
            self.delete(key)


# 全局缓存实例
cache = SimpleCache()


# 缓存 key 前缀
CACHE_KEYS = {
    "stats": "stats:",           # 统计数据缓存
    "user": "user:",             # 用户信息缓存
    "creds": "creds:",           # 凭证列表缓存
    "quota": "quota:",           # 配额缓存
}


def cached(prefix: str, ttl: int = 30):
    """
    缓存装饰器
    用法：
    @cached("stats", ttl=10)
    async def get_stats():
        ...
    """
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            # 生成缓存 key
            key = f"{prefix}:{func.__name__}:{hash(str(args) + str(kwargs))}"
            
            # 尝试从缓存获取
            result = cache.get(key)
            if result is not None:
                return result
            
            # 执行函数并缓存结果
            result = await func(*args, **kwargs)
            cache.set(key, result, ttl)
            return result
        return wrapper
    return decorator


def invalidate_cache(prefix: str = None):
    """清除缓存"""
    if prefix:
        cache.clear_prefix(prefix)
    else:
        cache.clear()
