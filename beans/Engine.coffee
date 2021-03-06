@import "cafe/engines/Sizzle"

package "cafe.beans"

  Engine: class Engine

    @classes: {}

    @beans: {}

    @addBeans: (json) ->
      for name, klass of json
        klass::getSizzle = -> return Sizzle

        @classes[ @getBeanName(name) ] = klass
      return

    @activate: () ->
      @parse(document.body)

    @parse: (context) ->
      ui = ["ui:bind", "ui:action"]
      selector = ("[#{ui.join("],[")}]").replace(/:/g, "\\:")

      for item in Sizzle(selector, context)
        ((item) ->
          for attr in ui
            ((attr) ->
              return unless expr = item.getAttribute(attr)

              liveAttrs = []

              try
                for ex in expr.split(/\s+/)
                  [name] = ex.split(".")

                  unless Engine.getBean(name)
                    liveAttrs.push(ex)
                    continue

                  switch attr
                    when "ui:bind"
                      Engine.callBind(ex, name, [item])
                    when "ui:action"
                      item.onclick = () ->
                        Engine.callAction(ex, name, Engine.getArguments(item, name))

              finally
                item.removeAttribute(attr)

                item.setAttribute(attr, liveAttrs.join(" ")) if liveAttrs.length

              return
            )(attr)
          return
        )(item)

      return

    @doCall: (expr, name, args, sg) ->
      @getBean(name)[@getMethod(expr, name, sg)](args...)

    @callBind: (expr, name, args) ->
      @doCall(expr, name, args, yes)

    @callAction: (expr, name, args) ->
      @doCall(expr, name, args)

    @getBean: (name) ->
      unless @hasBean(name)
        return null unless name of @classes

        @beans[name] = new @classes[name]()

      return @beans[name]

    @hasBean: (name) -> name of @beans

    @getArguments: (item, name) ->
      return [] unless attr = item.getAttribute("ui:arguments")

      args = attr.replace(/^\s+/, "").replace(/\s+$/, "").split(/\s+/)

      for arg, i in args
        args[i] = item if arg is "this"

      return args

    @getMethod: (expr, name, sg=null) ->
      method = expr.substr("#{name}.".length)

      if sg isnt null
        method = "#{if sg then "set" else "get"}#{@luStr(method)}"

      @throwNoMethod(method, name) if typeof @getBean(name)[method] isnt "function"

      return method

    @getBeanName: (klass) ->
      return @luStr(klass.replace(/Bean$/, ""), yes)

    @getBeanClass: (name) ->
      return "#{@luStr(name)}Bean"

    @throwNoMethod: (method, name) ->
      ex = new Error("#{method} is not a method of #{@getBeanClass(name)}")
      ex.name = "TypeError"
      throw ex

    @luStr: (str, low) ->
      return "#{str.substr(0, 1)["to#{if low then "Lower" else "Upper"}Case"]()}#{str.substr(1)}"