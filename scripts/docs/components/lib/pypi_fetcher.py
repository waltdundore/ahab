#!/usr/bin/env python3
"""
PyPI Metadata Fetcher Module

Fetches package metadata from PyPI JSON API.
Handles caching, error handling, and batch fetching.
"""

import os
import json
import time
from dataclasses import dataclass, field
from typing import List, Dict, Optional
from datetime import datetime, timedelta
import requests


@dataclass
class PackageMetadata:
    """Represents metadata for a Python package from PyPI"""
    name: str
    version: str
    summary: str
    description: str
    license: str
    home_page: str
    project_urls: Dict[str, str] = field(default_factory=dict)
    author: str = ""
    maintainer: str = ""
    classifiers: List[str] = field(default_factory=list)
    requires_dist: List[str] = field(default_factory=list)
    
    # Additional metadata
    pypi_url: str = ""
    source_repository: str = ""
    documentation_url: str = ""
    
    # Fetch metadata
    fetch_timestamp: Optional[datetime] = None
    fetch_error: Optional[str] = None


class PyPIFetcher:
    """Fetch package metadata from PyPI JSON API"""
    
    PYPI_API_BASE = "https://pypi.org/pypi"
    REQUEST_TIMEOUT = 10  # seconds
    MAX_RETRIES = 3
    RETRY_DELAY = 1  # seconds
    
    def __init__(self, cache_dir: Optional[str] = None):
        """
        Initialize PyPI fetcher.
        
        Args:
            cache_dir: Directory for caching API responses (optional)
        """
        self.cache_dir = cache_dir
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Ahab-Component-Documentation/1.0'
        })
    
    def fetch_metadata(self, package_name: str, use_cache: bool = True) -> PackageMetadata:
        """
        Fetch metadata for a package from PyPI.
        
        Args:
            package_name: Name of the package
            use_cache: Whether to use cached data if available
            
        Returns:
            PackageMetadata object
            
        Raises:
            requests.RequestException: If API request fails after retries
        """
        # Normalize package name (PyPI is case-insensitive)
        package_name = package_name.lower().replace('_', '-')
        
        # Check cache first
        if use_cache and self.cache_dir:
            cached_data = self._load_from_cache(package_name)
            if cached_data:
                return cached_data
        
        # Fetch from PyPI API
        url = f"{self.PYPI_API_BASE}/{package_name}/json"
        
        for attempt in range(self.MAX_RETRIES):
            try:
                response = self.session.get(url, timeout=self.REQUEST_TIMEOUT)
                response.raise_for_status()
                
                data = response.json()
                metadata = self._parse_pypi_response(package_name, data)
                
                # Cache the response
                if self.cache_dir:
                    self._save_to_cache(package_name, metadata, data)
                
                return metadata
                
            except requests.exceptions.HTTPError as e:
                if e.response.status_code == 404:
                    # Package not found - don't retry
                    return self._create_error_metadata(
                        package_name,
                        f"Package not found on PyPI: {package_name}"
                    )
                elif attempt < self.MAX_RETRIES - 1:
                    # Retry on other HTTP errors
                    time.sleep(self.RETRY_DELAY * (attempt + 1))
                    continue
                else:
                    return self._create_error_metadata(
                        package_name,
                        f"HTTP error fetching {package_name}: {e}"
                    )
                    
            except requests.exceptions.Timeout:
                if attempt < self.MAX_RETRIES - 1:
                    time.sleep(self.RETRY_DELAY * (attempt + 1))
                    continue
                else:
                    return self._create_error_metadata(
                        package_name,
                        f"Timeout fetching {package_name} after {self.MAX_RETRIES} attempts"
                    )
                    
            except requests.exceptions.RequestException as e:
                if attempt < self.MAX_RETRIES - 1:
                    time.sleep(self.RETRY_DELAY * (attempt + 1))
                    continue
                else:
                    return self._create_error_metadata(
                        package_name,
                        f"Request error fetching {package_name}: {e}"
                    )
                    
            except json.JSONDecodeError as e:
                return self._create_error_metadata(
                    package_name,
                    f"Invalid JSON response for {package_name}: {e}"
                )
        
        # Should not reach here, but just in case
        return self._create_error_metadata(
            package_name,
            f"Failed to fetch {package_name} after {self.MAX_RETRIES} attempts"
        )
    
    def fetch_batch(self, package_names: List[str], use_cache: bool = True) -> Dict[str, PackageMetadata]:
        """
        Fetch metadata for multiple packages.
        
        Args:
            package_names: List of package names
            use_cache: Whether to use cached data if available
            
        Returns:
            Dictionary mapping package name to PackageMetadata
        """
        results = {}
        
        for package_name in package_names:
            print(f"Fetching metadata for {package_name}...")
            metadata = self.fetch_metadata(package_name, use_cache=use_cache)
            results[package_name] = metadata
            
            # Small delay to be respectful to PyPI
            time.sleep(0.1)
        
        return results
    
    def _parse_pypi_response(self, package_name: str, data: dict) -> PackageMetadata:
        """
        Parse PyPI JSON response into PackageMetadata.
        
        Args:
            package_name: Name of the package
            data: JSON response from PyPI API
            
        Returns:
            PackageMetadata object
        """
        info = data.get('info', {})
        
        # Extract basic information
        name = info.get('name', package_name)
        version = info.get('version', '')
        summary = info.get('summary', '')
        description = info.get('description', '')
        license_str = info.get('license', '')
        home_page = info.get('home_page', '')
        author = info.get('author', '')
        maintainer = info.get('maintainer', '')
        
        # Extract project URLs
        project_urls = info.get('project_urls', {})
        if not project_urls:
            project_urls = {}
        
        # Extract classifiers
        classifiers = info.get('classifiers', [])
        
        # Extract dependencies
        requires_dist = info.get('requires_dist', [])
        if not requires_dist:
            requires_dist = []
        
        # Parse license from classifiers if not in license field
        if not license_str:
            license_str = self._extract_license_from_classifiers(classifiers)
        
        # Extract repository URL
        source_repository = self._extract_repository_url(project_urls, home_page)
        
        # Extract documentation URL
        documentation_url = self._extract_documentation_url(project_urls, home_page)
        
        # Build PyPI URL
        pypi_url = f"https://pypi.org/project/{name}/"
        
        return PackageMetadata(
            name=name,
            version=version,
            summary=summary,
            description=description,
            license=license_str,
            home_page=home_page,
            project_urls=project_urls,
            author=author,
            maintainer=maintainer,
            classifiers=classifiers,
            requires_dist=requires_dist,
            pypi_url=pypi_url,
            source_repository=source_repository,
            documentation_url=documentation_url,
            fetch_timestamp=datetime.now(),
            fetch_error=None
        )
    
    def _extract_license_from_classifiers(self, classifiers: List[str]) -> str:
        """Extract license from classifier strings"""
        for classifier in classifiers:
            if classifier.startswith('License ::'):
                # Extract the license name from the classifier
                # e.g., "License :: OSI Approved :: MIT License" -> "MIT License"
                parts = classifier.split('::')
                if len(parts) >= 3:
                    return parts[-1].strip()
        return ""
    
    def _extract_repository_url(self, project_urls: Dict[str, str], home_page: str) -> str:
        """Extract source repository URL from project URLs or home page"""
        # Check project_urls for common repository keys
        repo_keys = ['Source', 'Source Code', 'Repository', 'Code', 'GitHub', 'GitLab']
        for key in repo_keys:
            if key in project_urls:
                url = project_urls[key]
                if self._is_repository_url(url):
                    return url
        
        # Check home_page
        if self._is_repository_url(home_page):
            return home_page
        
        # Check all project_urls for repository patterns
        for url in project_urls.values():
            if self._is_repository_url(url):
                return url
        
        return ""
    
    def _extract_documentation_url(self, project_urls: Dict[str, str], home_page: str) -> str:
        """Extract documentation URL from project URLs"""
        doc_keys = ['Documentation', 'Docs', 'documentation', 'docs']
        for key in doc_keys:
            if key in project_urls:
                return project_urls[key]
        
        # If home_page looks like documentation, use it
        if home_page and any(pattern in home_page.lower() for pattern in ['readthedocs', 'docs', 'documentation']):
            return home_page
        
        return ""
    
    def _is_repository_url(self, url: str) -> bool:
        """Check if URL looks like a source repository"""
        if not url:
            return False
        
        url_lower = url.lower()
        repo_patterns = ['github.com', 'gitlab.com', 'bitbucket.org', 'git.']
        return any(pattern in url_lower for pattern in repo_patterns)
    
    def _create_error_metadata(self, package_name: str, error_message: str) -> PackageMetadata:
        """Create a PackageMetadata object for a failed fetch"""
        return PackageMetadata(
            name=package_name,
            version="",
            summary="",
            description="",
            license="",
            home_page="",
            fetch_timestamp=datetime.now(),
            fetch_error=error_message
        )
    
    def _load_from_cache(self, package_name: str) -> Optional[PackageMetadata]:
        """Load package metadata from cache if available and not expired"""
        if not self.cache_dir:
            return None
        
        cache_file = os.path.join(self.cache_dir, 'pypi', f"{package_name}.json")
        
        if not os.path.exists(cache_file):
            return None
        
        try:
            with open(cache_file, 'r', encoding='utf-8') as f:
                cached = json.load(f)
            
            # Check if cache is expired (24 hours)
            fetch_time = datetime.fromisoformat(cached.get('fetch_timestamp', ''))
            if datetime.now() - fetch_time > timedelta(hours=24):
                return None
            
            # Reconstruct PackageMetadata from cached data
            metadata = PackageMetadata(
                name=cached['name'],
                version=cached['version'],
                summary=cached['summary'],
                description=cached['description'],
                license=cached['license'],
                home_page=cached['home_page'],
                project_urls=cached.get('project_urls', {}),
                author=cached.get('author', ''),
                maintainer=cached.get('maintainer', ''),
                classifiers=cached.get('classifiers', []),
                requires_dist=cached.get('requires_dist', []),
                pypi_url=cached.get('pypi_url', ''),
                source_repository=cached.get('source_repository', ''),
                documentation_url=cached.get('documentation_url', ''),
                fetch_timestamp=fetch_time,
                fetch_error=cached.get('fetch_error')
            )
            
            print(f"  Using cached data for {package_name}")
            return metadata
            
        except (json.JSONDecodeError, KeyError, ValueError) as e:
            print(f"  Warning: Invalid cache file for {package_name}: {e}")
            return None
    
    def _save_to_cache(self, package_name: str, metadata: PackageMetadata, raw_data: dict):
        """Save package metadata to cache"""
        if not self.cache_dir:
            return
        
        cache_dir = os.path.join(self.cache_dir, 'pypi')
        os.makedirs(cache_dir, exist_ok=True)
        
        cache_file = os.path.join(cache_dir, f"{package_name}.json")
        
        # Convert metadata to dict for JSON serialization
        cache_data = {
            'name': metadata.name,
            'version': metadata.version,
            'summary': metadata.summary,
            'description': metadata.description,
            'license': metadata.license,
            'home_page': metadata.home_page,
            'project_urls': metadata.project_urls,
            'author': metadata.author,
            'maintainer': metadata.maintainer,
            'classifiers': metadata.classifiers,
            'requires_dist': metadata.requires_dist,
            'pypi_url': metadata.pypi_url,
            'source_repository': metadata.source_repository,
            'documentation_url': metadata.documentation_url,
            'fetch_timestamp': metadata.fetch_timestamp.isoformat() if metadata.fetch_timestamp else None,
            'fetch_error': metadata.fetch_error,
            'raw_pypi_data': raw_data  # Store raw data for debugging
        }
        
        try:
            with open(cache_file, 'w', encoding='utf-8') as f:
                json.dump(cache_data, f, indent=2)
        except Exception as e:
            print(f"  Warning: Failed to cache data for {package_name}: {e}")


def main():
    """Test the PyPI fetcher"""
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: python pypi_fetcher.py <package_name> [cache_dir]")
        sys.exit(1)
    
    package_name = sys.argv[1]
    cache_dir = sys.argv[2] if len(sys.argv) > 2 else None
    
    fetcher = PyPIFetcher(cache_dir=cache_dir)
    
    print(f"Fetching metadata for {package_name}...")
    metadata = fetcher.fetch_metadata(package_name)
    
    if metadata.fetch_error:
        print(f"\nError: {metadata.fetch_error}")
    else:
        print(f"\nPackage: {metadata.name}")
        print(f"Version: {metadata.version}")
        print(f"Summary: {metadata.summary}")
        print(f"License: {metadata.license}")
        print(f"Home Page: {metadata.home_page}")
        print(f"PyPI URL: {metadata.pypi_url}")
        print(f"Source Repository: {metadata.source_repository}")
        print(f"Documentation: {metadata.documentation_url}")
        print(f"Author: {metadata.author}")
        if metadata.maintainer:
            print(f"Maintainer: {metadata.maintainer}")
        print(f"\nClassifiers ({len(metadata.classifiers)}):")
        for classifier in metadata.classifiers[:5]:
            print(f"  - {classifier}")
        if len(metadata.classifiers) > 5:
            print(f"  ... and {len(metadata.classifiers) - 5} more")
        print(f"\nDependencies ({len(metadata.requires_dist)}):")
        for dep in metadata.requires_dist[:5]:
            print(f"  - {dep}")
        if len(metadata.requires_dist) > 5:
            print(f"  ... and {len(metadata.requires_dist) - 5} more")


if __name__ == "__main__":
    main()
