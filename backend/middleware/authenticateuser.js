function authenticateUser(req, res, next) {
  console.log('Authenticating user...');
  next(); // allow all for now
}

module.exports = authenticateUser;
