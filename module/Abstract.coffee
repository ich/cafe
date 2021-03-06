@import "cafe/Location"

package "cafe.module"

  # Абстрактный класс модулей
  # @author Roman.I.Kuzmin roman.i.kuzmin@gmail.com
  Abstract: class Abstract

    @defaultAction: "index"

    @settings:
      missingAction: "log"

    name: ""

    # Этот метод должен содержать инструкции по выполнению модуля
    # Этот метод должен быть переопределен
    run: () ->
      settings = @constructor.settings or Abstract.settings

      action = (Location.getAction() or settings.defaultAction or Abstract.defaultAction) + "Action"

      if actionIsMissing = typeof this[action] isnt "function"

        switch settings.missingAction
          when "ignore" then break
          when "log"
            console.log("Метод " + action + " для модуля " + @name + " не реализован!!!") unless @constructor.ignoreMissingAction

        return

      @beforeActionRun()

      results = this[action]()

      @afterActionRun()

      return results

    beforeActionRun: () ->

    afterActionRun: () ->
