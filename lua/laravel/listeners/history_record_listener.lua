return {
  event = require("laravel.events.command_run_event"),
  handle = function(data, app)
    local allow_duplicates = app("laravel.services.config").get("features.pickers.history.alluw_duplicates")

    if allow_duplicates then
      app("history"):add(data.job_id, data.cmd, data.args, data.options)
    else
      local already_exists = vim.tbl_contains(app("history"):get(), function(v)
        return vim.deep_equal(v.args, data.args)
      end, { predicate = true })

      if not already_exists then
        app("history"):add(data.job_id, data.cmd, data.args, data.options)
      end
    end
  end,
}
