# Contributing to Bazzite Node Setup

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## How to Contribute

### Reporting Issues

If you find a bug or have a suggestion:

1. Check if the issue already exists in [Issues](https://github.com/your-repo/issues)
2. If not, create a new issue with:
   - Clear title and description
   - Steps to reproduce (for bugs)
   - Expected vs actual behavior
   - Your system information:
     - Bazzite version
     - distrobox version
     - Output of `cat /etc/os-release`

### Suggesting Enhancements

We welcome suggestions for new features! Please:

1. Open an issue with the "enhancement" label
2. Describe the feature and its use case
3. Explain why it would be useful to users

### Pull Requests

1. **Fork the repository**
   ```bash
   git clone https://github.com/your-username/bazzite-node-setup.git
   cd bazzite-node-setup
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Follow the existing code style
   - Add comments for complex logic
   - Update documentation if needed

4. **Test your changes**
   ```bash
   # Test the setup script
   ./setup-dev-container.sh

   # Run the test suite
   ./test-setup.sh

   # Verify documentation
   ```

5. **Commit your changes**
   ```bash
   git add .
   git commit -m "Add feature: description of your changes"
   ```

6. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Open a Pull Request**
   - Provide a clear description of the changes
   - Reference any related issues
   - Include test results

## Development Guidelines

### Code Style

- Use consistent indentation (4 spaces for bash scripts)
- Add comments for non-obvious logic
- Use descriptive variable names
- Follow existing naming conventions

### Bash Scripts

- Always use `set -euo pipefail` at the start
- Quote variables: `"$variable"`
- Use `readonly` for constants
- Provide clear error messages
- Add help text with `--help` flag

### Documentation

- Update README.md for major changes
- Update USER_GUIDE.md for new features
- Add troubleshooting entries for common issues
- Keep QUICK_START.md concise

### Testing

Before submitting a PR:

1. Test on a clean Bazzite installation if possible
2. Run `./test-setup.sh` and ensure all tests pass
3. Test edge cases (missing dependencies, network issues, etc.)
4. Verify documentation is accurate

## Areas for Contribution

We especially welcome contributions in these areas:

### High Priority

- Additional package manager support
- More comprehensive error handling
- Performance optimizations
- Better progress indicators
- Automatic update mechanism

### Documentation

- More examples in USER_GUIDE.md
- Video tutorials
- Translations to other languages
- FAQ section

### Testing

- Additional test cases
- CI/CD integration
- Automated testing on different systems

### Features

- Support for other development tools (Python, Ruby, etc.)
- GUI installer option
- Configuration profiles for different use cases
- Integration with IDEs (VS Code, etc.)

## Code Review Process

1. Maintainers will review your PR within a few days
2. You may be asked to make changes
3. Once approved, your PR will be merged
4. Your contribution will be acknowledged in the changelog

## Recognition

All contributors will be:
- Listed in the CONTRIBUTORS file
- Mentioned in release notes
- Credited in the project README

## Questions?

If you have questions:
- Open an issue with the "question" label
- Join our community discussions
- Reach out to maintainers

## Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inclusive environment for everyone.

### Our Standards

- Be respectful and considerate
- Accept constructive criticism gracefully
- Focus on what's best for the community
- Show empathy towards others

### Unacceptable Behavior

- Harassment or discrimination
- Trolling or insulting comments
- Public or private harassment
- Publishing others' private information

### Enforcement

Violations may result in temporary or permanent ban from the project.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for making Bazzite Node Setup better! 🚀
