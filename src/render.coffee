###
# @author   Argi Karunia <arugikaru@yahoo.co.jp>
# @author   Originally by Teddy Hong <teddy.hong11@gmail.com>
# @link     https://github.com/tokopedia/Nodame
# @license  http://opensource.org/licenses/MIT
#
# @version  1.2.0
###

Path        = require('./path')
UUID        = require('node-uuid')
Redis       = require('./redis')
Async       = require('async')

APP         = nodame.config('app')
VIEW        = nodame.config('view')
COOKIE      = nodame.config('cookie')

class Render
  ###
  # @constructor
  ###
  constructor: (@req, @res) ->
    # Local variables
    @__locals = {}
    # Locales variable
    @__locals.locales = []
    # Set default page title
    @set('page_title', APP.title)
    #TODO Check redis for flash message (RENDY)
    # Set default file name
    @__file = 'index'
    return
  ###
  # @method Set local variable
  # @public
  # @param  string  key
  # @param  object  value
  ###
  set: (key, val) ->
    @__locals[key] = val
    return @
  ###
  # @method Set local variable
  # @public
  # @param  string  page title
  # @param  int     page number
  ###
  title: (title, page_num) ->
    separator     = APP.title_separator
    default_title = APP.title
    # TODO: change with i18n
    page_text     = 'Halaman'
    # Add separator
    title = "#{title} #{separator} #{default_title}"
    # Add page number if page exists
    title = "#{title}, #{page_text} #{page_num}" if page_num?
    # Assign title
    return @set('page_title', title)
  ###
  # @method Set menu
  # @public
  # @param  string  active menu
  ###
  menu: (active_menu) ->
    # Validate empty val
    throw new Error 'Missing active_menu args' unless active_menu?
    # Assign val
    return @set('menu', { active: active_menu })
  ###
  # @method Set assets name
  # @public
  # @param  string  assets name
  ###
  assets: (assets_name) ->
    # Validate empty val
    throw new Error 'Missing assets_name args' unless assets_name?
    # Assign val
    return @set('assets_name', assets_name)
  ###
  # @method Set locale
  # @public
  # @param  string  locale
  ###
  locale: (name) ->
    # Validate empty val
    throw new Erorr 'Missing locale args' unless name?
    # Validate value
    @__locals.locales.push(name) if @__locals.locales.indexOf(name) is -1
    return @
  ###
  # @method Set locales
  # @public
  # @param  object  locales
  ###
  locales: (locales) ->
    # Validate empty val
    throw new Erorr 'Missing locales args' unless locales?
    # Check if is array
    if typeof locales is 'object'
      @locale(name) for name in locales
    else
      @locale(locales)
    return @
  ###
  # @method Set module name
  # @public
  # @param  string  method name
  ###
  module: (@__module) ->
    # Validate empty val
    throw new Error 'Missing module args' unless @__module?
    return @
  ###
  # @method Set file name
  # @public
  # @param  string  file name
  ###
  file: (@__file) ->
    # Validate empty val
    throw new Error 'Missing file args' unless @__file?
    return @
  ###
  # @method Set view path
  # @public
  # @param  string  path
  ###
  path: (path) ->
    # Validate empty val
    throw new Error 'Missing path args' unless path?
    # Assign variables
    default_template  = VIEW.default_template
    template          = VIEW.template
    device            = VIEW.default_device
    adaptive          = VIEW.adaptive
    # Set 'phone' as 'mobile'
    # TODO: Set to switchable
    if @req.device?.type? and @req.device.type is 'phone' and adaptive
      device = 'mobile'
    # Set template to default when empty
    template = default_template unless template?
    # Set module and file
    # Get view path
    @__view_path = Path.join(device, template, path)
    return @
  ###
  # @method write response
  # @public
  ###
  send: (callback) -> 
    Async.parallel [
      (cb) => @__check_interstitial(cb)
    ], (err, obj) =>     
      @res.clearCookie 'fm',
        domain: ".#{COOKIE.domain}"
      throw new Error 'View path is undefined' unless @__view_path?
      return @res.render(@__view_path, @__locals, callback)
    return undefined
    
  ###
  # @method Pass interstitial view
  # @public
  # @param str key
  # @param obj value
  ###
  interstitial: (key, val, url) ->
    fm = @req.cookies.fm

    unless fm
      fm = UUID.v4()
      @res.cookie 'fm', fm,
        domain: ".#{COOKIE.domain}"
        expires: new Date(Date.now() + 600000)
        httpOnly: true

    redis = Redis.client()
    keyFm = "#{APP.name}:flashMessages:#{fm}"

    redis.set(keyFm, JSON.stringify({type:key,text:val}))
    redis.expire(keyFm, 600)

    @res.redirect(url)
    return undefined
    
  __check_interstitial: (cb) ->
    try
      fm = @req.cookies.fm
      
      redis = Redis.client()
      keyFm = "#{APP.name}:flashMessages:#{fm}"
      redis.get keyFm, (err, reply) =>
        if reply
           redis.del(keyFm)
        @set('messages', JSON.parse(reply))
        cb(null)
        return
    catch e
      cb(e)
      console.log(e)
    return

  ###
  # @method Pass message
  # @public
  # @param str key
  # @param obj value
  ###
  message: (key, val) ->
    messages =
      type: key
      text: val
    return @set('messages', messages)
  ###
  # @method Render 404
  # @public
  ###
  error_404: ->
    @view('errors/404')
    return @send()

module.exports = Render
