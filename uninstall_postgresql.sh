# List all postgres related packages
dpkg -l | grep postgres

# Remove all above listed
sudo apt-get --purge remove postgresql postgresql-*