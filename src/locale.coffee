i18n = require 'nodame/i18n'
path = require 'nodame/path'

locale = (app) ->
  i18n.expressBind app,
    locales: ['id', 'en']
    defaultLocale: 'id'
    cookieName: 'lang'
    directory: path.safe('locales/')

  app.use (req, res, next) ->
    req.i18n.setLocaleFromQuery()
    req.i18n.setLocaleFromCookie()
    next()
    return

  return

module.exports = locale
