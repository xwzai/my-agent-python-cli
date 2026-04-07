from setuptools import setup, find_packages

setup(
    name="my-agent-python-cli",
    version="1.0.0",
    packages=find_packages(),
    include_package_data=True,
    install_requires=[
        "click>=8.0.0",
        "rich>=10.0.0",
    ],
    entry_points={
        "console_scripts": [
            "my-agent-py=src.cli:cli",
        ],
    },
    author="My Agent",
    description="My Agent Python CLI - AI-powered coding assistant",
    python_requires=">=3.7",
)
