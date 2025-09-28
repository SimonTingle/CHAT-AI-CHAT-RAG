function authenticateUser(req, res, next) {
  // Development mode bypass
  if (process.env.NODE_ENV === 'development' && process.env.DISABLE_AUTH === 'true') {
    return next();
  }

  const userId = req.body?.userId || req.headers['x-user-id'] || req.query.userId;
  
  if (!userId) {
    return res.status(401).json({ 
      error: 'Authentication required',
      message: 'Please provide a valid user ID'
    });
  }

  // Basic validation
  if (typeof userId !== 'string' || userId.length > 100) {
    return res.status(400).json({ error: 'Invalid user ID format' });
  }

  req.userId = userId;
  next();
}

module.exports = { authenticateUser };
