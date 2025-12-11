#!/usr/bin/env python3
"""
Git Repository Analyzer Module

Analyzes git repositories to gather metadata and maintenance status.
Supports GitHub and GitLab APIs.
"""

import os
import json
import time
import re
from dataclasses import dataclass
from typing import Optional, Dict
from datetime import datetime, timedelta
from urllib.parse import urlparse
import requests


@dataclass
class RepositoryMetadata:
    """Represents metadata for a git repository"""
    url: str
    platform: str  # "github", "gitlab", "unknown"
    stars: int
    forks: int
    open_issues: int
    open_prs: int
    last_commit_date: Optional[datetime]
    contributors_count: int
    license: str
    readme_excerpt: str
    
    # Fetch metadata
    fetch_timestamp: Optional[datetime] = None
    fetch_error: Optional[str] = None


@dataclass
class MaintenanceStatus:
    """Represents maintenance status of a repository"""
    is_active: bool  # Commit in last 6 months
    last_release_date: Optional[datetime]
    days_since_last_commit: int
    is_deprecated: bool
    deprecation_notice: Optional[str]
    status_label: str  # "Active", "Maintained", "Stale", "Deprecated"


class GitAnalyzer:
    """Analyze git repositories for stats and maintenance status"""
    
    REQUEST_TIMEOUT = 10  # seconds
    MAX_RETRIES = 3
    RETRY_DELAY = 1  # seconds
    
    # Maintenance status thresholds
    ACTIVE_THRESHOLD_DAYS = 180  # 6 months
    MAINTAINED_THRESHOLD_DAYS = 365  # 1 year
    
    def __init__(self, cache_dir: Optional[str] = None, github_token: Optional[str] = None):
        """
        Initialize Git analyzer.
        
        Args:
            cache_dir: Directory for caching API responses (optional)
            github_token: GitHub API token for higher rate limits (optional)
        """
        self.cache_dir = cache_dir
        self.github_token = github_token or os.environ.get('GITHUB_TOKEN')
        
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Ahab-Component-Documentation/1.0',
            'Accept': 'application/vnd.github.v3+json'
        })
        
        if self.github_token:
            self.session.headers['Authorization'] = f'token {self.github_token}'
    
    def analyze_repository(self, repo_url: str, use_cache: bool = True) -> RepositoryMetadata:
        """
        Analyze a git repository.
        
        Args:
            repo_url: URL of the repository
            use_cache: Whether to use cached data if available
            
        Returns:
            RepositoryMetadata object
        """
        if not repo_url:
            return self._create_error_metadata(repo_url, "Empty repository URL")
        
        # Check cache first
        if use_cache and self.cache_dir:
            cached_data = self._load_from_cache(repo_url)
            if cached_data:
                return cached_data
        
        # Determine platform
        platform = self._detect_platform(repo_url)
        
        if platform == "github":
            metadata = self._analyze_github(repo_url)
        elif platform == "gitlab":
            metadata = self._analyze_gitlab(repo_url)
        else:
            metadata = self._create_error_metadata(
                repo_url,
                f"Unsupported platform: {platform}"
            )
        
        # Cache the result
        if self.cache_dir and not metadata.fetch_error:
            self._save_to_cache(repo_url, metadata)
        
        return metadata
    
    def check_maintenance_status(self, repo_url: str) -> MaintenanceStatus:
        """
        Check if repository is actively maintained.
        
        Args:
            repo_url: URL of the repository
            
        Returns:
            MaintenanceStatus object
        """
        metadata = self.analyze_repository(repo_url)
        
        if metadata.fetch_error or not metadata.last_commit_date:
            return MaintenanceStatus(
                is_active=False,
                last_release_date=None,
                days_since_last_commit=-1,
                is_deprecated=False,
                deprecation_notice=None,
                status_label="Unknown"
            )
        
        # Calculate days since last commit
        days_since_commit = (datetime.now() - metadata.last_commit_date).days
        
        # Determine status
        is_active = days_since_commit <= self.ACTIVE_THRESHOLD_DAYS
        is_maintained = days_since_commit <= self.MAINTAINED_THRESHOLD_DAYS
        
        # Check for deprecation notice in README
        is_deprecated = self._check_deprecation(metadata.readme_excerpt)
        deprecation_notice = None
        if is_deprecated:
            deprecation_notice = "Repository appears to be deprecated (check README)"
        
        # Determine status label
        if is_deprecated:
            status_label = "Deprecated"
        elif is_active:
            status_label = "Active"
        elif is_maintained:
            status_label = "Maintained"
        else:
            status_label = "Stale"
        
        return MaintenanceStatus(
            is_active=is_active,
            last_release_date=None,  # Would need separate API call
            days_since_last_commit=days_since_commit,
            is_deprecated=is_deprecated,
            deprecation_notice=deprecation_notice,
            status_label=status_label
        )
    
    def _detect_platform(self, repo_url: str) -> str:
        """Detect the platform from repository URL"""
        url_lower = repo_url.lower()
        
        if 'github.com' in url_lower:
            return 'github'
        elif 'gitlab.com' in url_lower:
            return 'gitlab'
        else:
            return 'unknown'
    
    def _parse_github_url(self, repo_url: str) -> Optional[tuple]:
        """
        Parse GitHub URL to extract owner and repo name.
        
        Returns:
            Tuple of (owner, repo) or None if invalid
        """
        # Handle various GitHub URL formats
        patterns = [
            r'github\.com[:/]([^/]+)/([^/\.]+)',  # https://github.com/owner/repo or git@github.com:owner/repo
            r'github\.com/([^/]+)/([^/]+?)(?:\.git)?$',  # With or without .git
        ]
        
        for pattern in patterns:
            match = re.search(pattern, repo_url)
            if match:
                owner, repo = match.groups()
                # Remove .git suffix if present
                repo = repo.rstrip('.git')
                return (owner, repo)
        
        return None
    
    def _analyze_github(self, repo_url: str) -> RepositoryMetadata:
        """Analyze a GitHub repository"""
        parsed = self._parse_github_url(repo_url)
        if not parsed:
            return self._create_error_metadata(
                repo_url,
                f"Could not parse GitHub URL: {repo_url}"
            )
        
        owner, repo = parsed
        api_url = f"https://api.github.com/repos/{owner}/{repo}"
        
        for attempt in range(self.MAX_RETRIES):
            try:
                response = self.session.get(api_url, timeout=self.REQUEST_TIMEOUT)
                
                # Check rate limiting
                if response.status_code == 403:
                    rate_limit_remaining = response.headers.get('X-RateLimit-Remaining', '0')
                    if rate_limit_remaining == '0':
                        reset_time = response.headers.get('X-RateLimit-Reset', '')
                        return self._create_error_metadata(
                            repo_url,
                            f"GitHub API rate limit exceeded. Reset at: {reset_time}"
                        )
                
                response.raise_for_status()
                data = response.json()
                
                # Parse response
                metadata = self._parse_github_response(repo_url, data)
                
                # Fetch additional data (commits, contributors)
                self._enrich_github_metadata(metadata, owner, repo)
                
                return metadata
                
            except requests.exceptions.HTTPError as e:
                if e.response.status_code == 404:
                    return self._create_error_metadata(
                        repo_url,
                        f"Repository not found: {repo_url}"
                    )
                elif attempt < self.MAX_RETRIES - 1:
                    time.sleep(self.RETRY_DELAY * (attempt + 1))
                    continue
                else:
                    return self._create_error_metadata(
                        repo_url,
                        f"HTTP error analyzing {repo_url}: {e}"
                    )
                    
            except requests.exceptions.Timeout:
                if attempt < self.MAX_RETRIES - 1:
                    time.sleep(self.RETRY_DELAY * (attempt + 1))
                    continue
                else:
                    return self._create_error_metadata(
                        repo_url,
                        f"Timeout analyzing {repo_url}"
                    )
                    
            except Exception as e:
                if attempt < self.MAX_RETRIES - 1:
                    time.sleep(self.RETRY_DELAY * (attempt + 1))
                    continue
                else:
                    return self._create_error_metadata(
                        repo_url,
                        f"Error analyzing {repo_url}: {e}"
                    )
        
        return self._create_error_metadata(
            repo_url,
            f"Failed to analyze {repo_url} after {self.MAX_RETRIES} attempts"
        )
    
    def _parse_github_response(self, repo_url: str, data: dict) -> RepositoryMetadata:
        """Parse GitHub API response"""
        # Extract basic stats
        stars = data.get('stargazers_count', 0)
        forks = data.get('forks_count', 0)
        open_issues = data.get('open_issues_count', 0)  # Includes PRs
        
        # Extract license
        license_info = data.get('license', {})
        license_str = license_info.get('spdx_id', '') if license_info else ''
        
        # Extract last push date
        pushed_at = data.get('pushed_at', '')
        last_commit_date = None
        if pushed_at:
            try:
                last_commit_date = datetime.strptime(pushed_at, '%Y-%m-%dT%H:%M:%SZ')
            except ValueError:
                pass
        
        # Get README excerpt (first 500 chars of description)
        description = data.get('description', '')
        readme_excerpt = description[:500] if description else ''
        
        return RepositoryMetadata(
            url=repo_url,
            platform='github',
            stars=stars,
            forks=forks,
            open_issues=open_issues,
            open_prs=0,  # Will be enriched separately
            last_commit_date=last_commit_date,
            contributors_count=0,  # Will be enriched separately
            license=license_str,
            readme_excerpt=readme_excerpt,
            fetch_timestamp=datetime.now(),
            fetch_error=None
        )
    
    def _enrich_github_metadata(self, metadata: RepositoryMetadata, owner: str, repo: str):
        """Enrich metadata with additional GitHub API calls"""
        # Get contributors count (limited to avoid rate limiting)
        try:
            contributors_url = f"https://api.github.com/repos/{owner}/{repo}/contributors"
            response = self.session.get(
                contributors_url,
                params={'per_page': 1, 'anon': 'true'},
                timeout=self.REQUEST_TIMEOUT
            )
            if response.status_code == 200:
                # GitHub returns total count in Link header
                link_header = response.headers.get('Link', '')
                if 'last' in link_header:
                    # Parse last page number from Link header
                    match = re.search(r'page=(\d+)>; rel="last"', link_header)
                    if match:
                        metadata.contributors_count = int(match.group(1))
                else:
                    # If no pagination, count is small
                    metadata.contributors_count = len(response.json())
        except Exception:
            # Don't fail if we can't get contributors
            pass
        
        # Get pull requests count
        try:
            pulls_url = f"https://api.github.com/repos/{owner}/{repo}/pulls"
            response = self.session.get(
                pulls_url,
                params={'state': 'open', 'per_page': 1},
                timeout=self.REQUEST_TIMEOUT
            )
            if response.status_code == 200:
                link_header = response.headers.get('Link', '')
                if 'last' in link_header:
                    match = re.search(r'page=(\d+)>; rel="last"', link_header)
                    if match:
                        metadata.open_prs = int(match.group(1))
                else:
                    metadata.open_prs = len(response.json())
        except Exception:
            pass
    
    def _analyze_gitlab(self, repo_url: str) -> RepositoryMetadata:
        """Analyze a GitLab repository"""
        # Parse GitLab URL
        parsed = urlparse(repo_url)
        path = parsed.path.strip('/')
        
        # Remove .git suffix
        if path.endswith('.git'):
            path = path[:-4]
        
        # URL encode the project path
        import urllib.parse
        project_path = urllib.parse.quote(path, safe='')
        
        api_url = f"https://gitlab.com/api/v4/projects/{project_path}"
        
        for attempt in range(self.MAX_RETRIES):
            try:
                response = self.session.get(api_url, timeout=self.REQUEST_TIMEOUT)
                response.raise_for_status()
                data = response.json()
                
                # Parse response
                stars = data.get('star_count', 0)
                forks = data.get('forks_count', 0)
                open_issues = data.get('open_issues_count', 0)
                
                # Last activity
                last_activity = data.get('last_activity_at', '')
                last_commit_date = None
                if last_activity:
                    try:
                        last_commit_date = datetime.strptime(
                            last_activity,
                            '%Y-%m-%dT%H:%M:%S.%fZ'
                        )
                    except ValueError:
                        try:
                            last_commit_date = datetime.strptime(
                                last_activity,
                                '%Y-%m-%dT%H:%M:%SZ'
                            )
                        except ValueError:
                            pass
                
                # Description
                description = data.get('description', '')
                readme_excerpt = description[:500] if description else ''
                
                return RepositoryMetadata(
                    url=repo_url,
                    platform='gitlab',
                    stars=stars,
                    forks=forks,
                    open_issues=open_issues,
                    open_prs=0,  # GitLab uses merge requests
                    last_commit_date=last_commit_date,
                    contributors_count=0,
                    license='',  # Would need separate API call
                    readme_excerpt=readme_excerpt,
                    fetch_timestamp=datetime.now(),
                    fetch_error=None
                )
                
            except requests.exceptions.HTTPError as e:
                if e.response.status_code == 404:
                    return self._create_error_metadata(
                        repo_url,
                        f"Repository not found: {repo_url}"
                    )
                elif attempt < self.MAX_RETRIES - 1:
                    time.sleep(self.RETRY_DELAY * (attempt + 1))
                    continue
                else:
                    return self._create_error_metadata(
                        repo_url,
                        f"HTTP error analyzing {repo_url}: {e}"
                    )
                    
            except Exception as e:
                if attempt < self.MAX_RETRIES - 1:
                    time.sleep(self.RETRY_DELAY * (attempt + 1))
                    continue
                else:
                    return self._create_error_metadata(
                        repo_url,
                        f"Error analyzing {repo_url}: {e}"
                    )
        
        return self._create_error_metadata(
            repo_url,
            f"Failed to analyze {repo_url} after {self.MAX_RETRIES} attempts"
        )
    
    def _check_deprecation(self, readme_excerpt: str) -> bool:
        """Check if README contains deprecation notice"""
        if not readme_excerpt:
            return False
        
        deprecation_keywords = [
            'deprecated',
            'no longer maintained',
            'unmaintained',
            'archived',
            'obsolete',
            'end of life',
            'eol'
        ]
        
        readme_lower = readme_excerpt.lower()
        return any(keyword in readme_lower for keyword in deprecation_keywords)
    
    def _create_error_metadata(self, repo_url: str, error_message: str) -> RepositoryMetadata:
        """Create a RepositoryMetadata object for a failed fetch"""
        return RepositoryMetadata(
            url=repo_url,
            platform='unknown',
            stars=0,
            forks=0,
            open_issues=0,
            open_prs=0,
            last_commit_date=None,
            contributors_count=0,
            license='',
            readme_excerpt='',
            fetch_timestamp=datetime.now(),
            fetch_error=error_message
        )
    
    def _load_from_cache(self, repo_url: str) -> Optional[RepositoryMetadata]:
        """Load repository metadata from cache if available and not expired"""
        if not self.cache_dir:
            return None
        
        # Create cache key from URL
        cache_key = self._url_to_cache_key(repo_url)
        cache_file = os.path.join(self.cache_dir, 'github', f"{cache_key}.json")
        
        if not os.path.exists(cache_file):
            return None
        
        try:
            with open(cache_file, 'r', encoding='utf-8') as f:
                cached = json.load(f)
            
            # Check if cache is expired (24 hours)
            fetch_time = datetime.fromisoformat(cached.get('fetch_timestamp', ''))
            if datetime.now() - fetch_time > timedelta(hours=24):
                return None
            
            # Reconstruct RepositoryMetadata from cached data
            last_commit_date = None
            if cached.get('last_commit_date'):
                last_commit_date = datetime.fromisoformat(cached['last_commit_date'])
            
            metadata = RepositoryMetadata(
                url=cached['url'],
                platform=cached['platform'],
                stars=cached['stars'],
                forks=cached['forks'],
                open_issues=cached['open_issues'],
                open_prs=cached['open_prs'],
                last_commit_date=last_commit_date,
                contributors_count=cached['contributors_count'],
                license=cached['license'],
                readme_excerpt=cached['readme_excerpt'],
                fetch_timestamp=fetch_time,
                fetch_error=cached.get('fetch_error')
            )
            
            print(f"  Using cached data for {repo_url}")
            return metadata
            
        except (json.JSONDecodeError, KeyError, ValueError) as e:
            print(f"  Warning: Invalid cache file for {repo_url}: {e}")
            return None
    
    def _save_to_cache(self, repo_url: str, metadata: RepositoryMetadata):
        """Save repository metadata to cache"""
        if not self.cache_dir:
            return
        
        cache_dir = os.path.join(self.cache_dir, 'github')
        os.makedirs(cache_dir, exist_ok=True)
        
        cache_key = self._url_to_cache_key(repo_url)
        cache_file = os.path.join(cache_dir, f"{cache_key}.json")
        
        # Convert metadata to dict for JSON serialization
        cache_data = {
            'url': metadata.url,
            'platform': metadata.platform,
            'stars': metadata.stars,
            'forks': metadata.forks,
            'open_issues': metadata.open_issues,
            'open_prs': metadata.open_prs,
            'last_commit_date': metadata.last_commit_date.isoformat() if metadata.last_commit_date else None,
            'contributors_count': metadata.contributors_count,
            'license': metadata.license,
            'readme_excerpt': metadata.readme_excerpt,
            'fetch_timestamp': metadata.fetch_timestamp.isoformat() if metadata.fetch_timestamp else None,
            'fetch_error': metadata.fetch_error
        }
        
        try:
            with open(cache_file, 'w', encoding='utf-8') as f:
                json.dump(cache_data, f, indent=2)
        except Exception as e:
            print(f"  Warning: Failed to cache data for {repo_url}: {e}")
    
    def _url_to_cache_key(self, repo_url: str) -> str:
        """Convert repository URL to cache key"""
        # Extract owner/repo from URL
        parsed = self._parse_github_url(repo_url)
        if parsed:
            owner, repo = parsed
            return f"{owner}_{repo}"
        
        # Fallback: use hash of URL
        import hashlib
        return hashlib.md5(repo_url.encode()).hexdigest()


def main():
    """Test the git analyzer"""
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: python git_analyzer.py <repo_url> [cache_dir]")
        sys.exit(1)
    
    repo_url = sys.argv[1]
    cache_dir = sys.argv[2] if len(sys.argv) > 2 else None
    
    analyzer = GitAnalyzer(cache_dir=cache_dir)
    
    print(f"Analyzing repository: {repo_url}")
    metadata = analyzer.analyze_repository(repo_url)
    
    if metadata.fetch_error:
        print(f"\nError: {metadata.fetch_error}")
    else:
        print(f"\nPlatform: {metadata.platform}")
        print(f"Stars: {metadata.stars}")
        print(f"Forks: {metadata.forks}")
        print(f"Open Issues: {metadata.open_issues}")
        print(f"Open PRs: {metadata.open_prs}")
        print(f"Contributors: {metadata.contributors_count}")
        print(f"License: {metadata.license}")
        if metadata.last_commit_date:
            print(f"Last Commit: {metadata.last_commit_date.strftime('%Y-%m-%d')}")
        print(f"\nREADME Excerpt:")
        print(f"  {metadata.readme_excerpt[:200]}...")
        
        # Check maintenance status
        print(f"\nMaintenance Status:")
        status = analyzer.check_maintenance_status(repo_url)
        print(f"  Status: {status.status_label}")
        print(f"  Active: {status.is_active}")
        print(f"  Days since last commit: {status.days_since_last_commit}")
        if status.is_deprecated:
            print(f"  Deprecation: {status.deprecation_notice}")


if __name__ == "__main__":
    main()
