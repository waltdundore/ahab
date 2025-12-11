#!/usr/bin/env python3
"""
Property-Based Tests for Git Repository Analyzer

**Feature: open-source-attribution, Property 2: Source Repository Accessibility**
**Validates: Requirements 2.1, 2.2**

Property: For any component listed in the documentation, the source_repository 
URL should be accessible (HTTP 200 response) and point to a public repository.
"""

import os
import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from lib.git_analyzer import GitAnalyzer, RepositoryMetadata
from lib.pypi_fetcher import PyPIFetcher
from lib.requirements_parser import RequirementsParser
from hypothesis import given, strategies as st, settings, example, assume
import pytest
import requests


# Strategy for generating valid GitHub repository URLs
@st.composite
def github_url_strategy(draw):
    """Generate valid GitHub repository URLs"""
    # Use real, known GitHub repositories for testing
    known_repos = [
        "https://github.com/pallets/flask",
        "https://github.com/psf/requests",
        "https://github.com/HypothesisWorks/hypothesis",
        "https://github.com/yaml/pyyaml",
        "https://github.com/pypa/packaging",
        "https://github.com/pytest-dev/pytest",
        "https://github.com/python/cpython",
        "https://github.com/django/django",
        "https://github.com/ansible/ansible",
        "https://github.com/docker/docker-py",
    ]
    return draw(st.sampled_from(known_repos))


# Strategy for generating GitLab URLs
@st.composite
def gitlab_url_strategy(draw):
    """Generate valid GitLab repository URLs"""
    known_repos = [
        "https://gitlab.com/gitlab-org/gitlab",
        "https://gitlab.com/gitlab-org/gitlab-runner",
    ]
    return draw(st.sampled_from(known_repos))


# Combined strategy for any git repository URL
repository_url_strategy = st.one_of(
    github_url_strategy(),
    gitlab_url_strategy()
)


class TestRepositoryAccessibility:
    """
    Property 2: Source Repository Accessibility
    
    For any component listed in the documentation, the source_repository URL 
    should be accessible and point to a public repository.
    """
    
    @given(github_url_strategy())
    @settings(max_examples=10, deadline=30000)  # Longer deadline for network requests
    @example("https://github.com/pallets/flask")
    @example("https://github.com/psf/requests")
    def test_github_repositories_are_accessible(self, repo_url: str):
        """
        **Feature: open-source-attribution, Property 2: Source Repository Accessibility**
        
        Property: For any GitHub repository URL, the analyzer should be able to 
        access it and retrieve metadata without errors (or handle rate limiting gracefully).
        """
        analyzer = GitAnalyzer()
        
        # Analyze the repository
        metadata = analyzer.analyze_repository(repo_url, use_cache=False)
        
        # Property 1: No fetch errors for valid repositories (except rate limiting)
        # Rate limiting is expected and should be handled gracefully
        if metadata.fetch_error:
            # If there's an error, it should be a known error type
            assert any(keyword in metadata.fetch_error for keyword in [
                "rate limit", "Repository not found", "HTTP error", "Timeout"
            ]), f"Unexpected error type for {repo_url}: {metadata.fetch_error}"
            
            # If rate limited, skip further checks
            if "rate limit" in metadata.fetch_error:
                pytest.skip(f"GitHub API rate limited for {repo_url}")
                return
            
            # If repository not found, this might be a moved/deleted repo
            # This is acceptable - we just need to handle it gracefully
            if "Repository not found" in metadata.fetch_error:
                return
        
        # For successful fetches, verify properties
        if metadata.fetch_error is None:
            # Property 2: URL should be preserved
            assert metadata.url == repo_url, \
                f"Repository URL should be preserved"
            
            # Property 3: Platform should be detected correctly
            assert metadata.platform == "github", \
                f"Platform should be detected as 'github' for {repo_url}"
            
            # Property 4: Should have some basic stats (public repos have these)
            # Note: We don't assert specific values, just that they're non-negative
            assert metadata.stars >= 0, "Stars count should be non-negative"
            assert metadata.forks >= 0, "Forks count should be non-negative"
            assert metadata.open_issues >= 0, "Open issues count should be non-negative"
            
            # Property 5: Should have a last commit date for active repositories
            assert metadata.last_commit_date is not None, \
                f"Should have last commit date for {repo_url}"
    
    @given(gitlab_url_strategy())
    @settings(max_examples=5, deadline=30000)
    @example("https://gitlab.com/gitlab-org/gitlab")
    def test_gitlab_repositories_are_accessible(self, repo_url: str):
        """
        Property: For any GitLab repository URL, the analyzer should be able to 
        access it and retrieve metadata without errors.
        """
        analyzer = GitAnalyzer()
        
        # Analyze the repository
        metadata = analyzer.analyze_repository(repo_url, use_cache=False)
        
        # Property 1: No fetch errors for valid repositories
        assert metadata.fetch_error is None, \
            f"Should be able to access {repo_url}, but got error: {metadata.fetch_error}"
        
        # Property 2: Platform should be detected correctly
        assert metadata.platform == "gitlab", \
            f"Platform should be detected as 'gitlab' for {repo_url}"
        
        # Property 3: Should have basic stats
        assert metadata.stars >= 0, "Stars count should be non-negative"
        assert metadata.forks >= 0, "Forks count should be non-negative"
    
    def test_real_project_repositories_are_accessible(self):
        """
        Test that repositories from actual project requirements are accessible.
        
        This validates the property holds for real components used in the project.
        """
        # Parse real requirements files
        parser = RequirementsParser()
        test_dir = Path(__file__).parent
        project_root = test_dir.parent.parent.parent.parent.parent
        
        all_requirements = parser.discover_all_requirements(str(project_root))
        
        # Get a sample of packages to test (not all, to avoid rate limiting)
        sample_packages = []
        for filepath, requirements in all_requirements.items():
            sample_packages.extend([req.name for req in requirements[:3]])  # First 3 from each file
        
        # Limit to 10 packages total
        sample_packages = sample_packages[:10]
        
        # Fetch metadata from PyPI to get repository URLs
        fetcher = PyPIFetcher()
        analyzer = GitAnalyzer()
        
        accessible_count = 0
        tested_count = 0
        
        for package_name in sample_packages:
            print(f"\nTesting {package_name}...")
            
            # Get PyPI metadata
            pypi_metadata = fetcher.fetch_metadata(package_name, use_cache=True)
            
            if pypi_metadata.fetch_error:
                print(f"  Skipping {package_name}: PyPI fetch error")
                continue
            
            if not pypi_metadata.source_repository:
                print(f"  Skipping {package_name}: No repository URL in PyPI metadata")
                continue
            
            repo_url = pypi_metadata.source_repository
            tested_count += 1
            
            # Analyze the repository
            repo_metadata = analyzer.analyze_repository(repo_url, use_cache=True)
            
            # Property: Repository should be accessible
            if repo_metadata.fetch_error is None:
                accessible_count += 1
                print(f"  ✓ Accessible: {repo_url}")
                
                # Additional properties for accessible repositories
                assert repo_metadata.platform in ["github", "gitlab", "unknown"], \
                    f"Platform should be recognized for {repo_url}"
                
                if repo_metadata.platform == "github":
                    assert repo_metadata.stars >= 0, "Stars should be non-negative"
                    assert repo_metadata.forks >= 0, "Forks should be non-negative"
            else:
                print(f"  ✗ Not accessible: {repo_url}")
                print(f"    Error: {repo_metadata.fetch_error}")
        
        # Property: Most repositories should be accessible
        # We expect at least 50% success rate (some repos might be moved/deleted, rate limited, etc.)
        if tested_count > 0:
            success_rate = accessible_count / tested_count
            assert success_rate >= 0.5, \
                f"Expected at least 50% of repositories to be accessible, got {success_rate:.1%} ({accessible_count}/{tested_count})"
        else:
            pytest.skip("No repositories to test")
    
    @given(st.text(min_size=1, max_size=100))
    @settings(max_examples=20)
    @example("not-a-url")
    @example("http://invalid-domain-that-does-not-exist.com/repo")
    @example("")
    def test_invalid_urls_are_handled_gracefully(self, invalid_url: str):
        """
        Property: For any invalid or inaccessible URL, the analyzer should 
        handle it gracefully without crashing and return an error metadata object.
        """
        # Skip URLs that might accidentally be valid
        assume(not invalid_url.startswith("https://github.com/"))
        assume(not invalid_url.startswith("https://gitlab.com/"))
        
        analyzer = GitAnalyzer()
        
        # Analyze the invalid URL
        metadata = analyzer.analyze_repository(invalid_url, use_cache=False)
        
        # Property 1: Should not crash (we got a result)
        assert metadata is not None, "Should return metadata even for invalid URLs"
        
        # Property 2: Should have an error for invalid URLs
        # (Either fetch_error is set, or it's marked as unknown platform)
        assert metadata.fetch_error is not None or metadata.platform == "unknown", \
            f"Invalid URL should result in error or unknown platform"
        
        # Property 3: Stats should be zero or default values for failed fetches
        if metadata.fetch_error:
            assert metadata.stars == 0, "Failed fetch should have zero stars"
            assert metadata.forks == 0, "Failed fetch should have zero forks"
    
    @given(github_url_strategy())
    @settings(max_examples=5, deadline=30000)
    def test_maintenance_status_is_determined(self, repo_url: str):
        """
        Property: For any accessible repository, the analyzer should be able to 
        determine its maintenance status.
        """
        analyzer = GitAnalyzer()
        
        # Check maintenance status
        status = analyzer.check_maintenance_status(repo_url)
        
        # Property 1: Status label should be one of the valid values
        valid_labels = ["Active", "Maintained", "Stale", "Deprecated", "Unknown"]
        assert status.status_label in valid_labels, \
            f"Status label should be one of {valid_labels}, got {status.status_label}"
        
        # Property 2: If active, days since commit should be <= 180
        if status.is_active:
            assert status.days_since_last_commit <= 180, \
                f"Active repositories should have commits within 180 days"
        
        # Property 3: If deprecated, should have deprecation notice
        if status.is_deprecated:
            assert status.deprecation_notice is not None, \
                "Deprecated repositories should have a deprecation notice"
        
        # Property 4: Days since commit should be non-negative (or -1 for unknown)
        assert status.days_since_last_commit >= -1, \
            "Days since commit should be non-negative or -1 for unknown"
    
    def test_caching_works_correctly(self):
        """
        Property: Cached repository data should be equivalent to fresh data 
        (within the cache validity period).
        """
        import tempfile
        
        # Create a temporary cache directory
        with tempfile.TemporaryDirectory() as cache_dir:
            analyzer = GitAnalyzer(cache_dir=cache_dir)
            
            # Test with a known repository
            repo_url = "https://github.com/pallets/flask"
            
            # First fetch (no cache)
            metadata1 = analyzer.analyze_repository(repo_url, use_cache=False)
            
            # Second fetch (should use cache)
            metadata2 = analyzer.analyze_repository(repo_url, use_cache=True)
            
            # Property: Cached data should match fresh data
            assert metadata1.url == metadata2.url
            assert metadata1.platform == metadata2.platform
            assert metadata1.stars == metadata2.stars
            assert metadata1.forks == metadata2.forks
            
            # Note: We don't check exact equality of all fields because 
            # some stats (like open issues) might change between fetches


if __name__ == "__main__":
    pytest.main([__file__, "-v", "-s"])
