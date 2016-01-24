class window.Bulky
        constructor: (valid_record_url, submit_url) ->
                @enabled = false
                @deletes   = {}
                @changes   = {}
                @additions = {}
                @add_counter = 0

                @valid_record_url = valid_record_url
                @submit_url = submit_url

                @hooked = false
                @hook()

        panel_update: () ->
                added = (a for own a of @additions).length
                changed = (c for own c of @changes).length
                deleted = (d for own d of @deletes).length

                $('#bulk-panel .added').text(added)
                $('#bulk-panel .changed').text(changed)
                $('#bulk-panel .deleted').text(deleted)

        marked_for_delete: (id) ->
                return @deletes[id]

        update: (id, attr, value) ->
                @changes[id] or= {}
                @changes[id][attr] = value
                $("#record-#{id}").addClass('modified')

                @panel_update()

        add: (rec) ->
                @add_counter += 1
                @additions[@add_counter] = rec

                @panel_update()
                @add_counter

        validate_add: (arr) ->
                _me = this
                $.ajax {
                        url: @valid_record_url,
                        type: 'post',
                        dataType: 'json',
                        data: arr,
                        success: (data) ->
                                if data.errors
                                        alert(data.errors)
                                        return

                                id = _me.add(data.record)
                                _me.render_new(id, data.record)
                        error: () ->
                                alert('There was an error processing your request...')
                        }

        render_new: (id, rec) ->
                el = $('#new_records .clone').clone()
                el.removeClass('clone').removeClass('hidden')

                el.attr('id', "fresh-#{id}")
                for attr in ['name', 'ttl', 'type', 'prio', 'content']
                        if rec[attr]
                                el.find(".#{attr}").text(rec[attr])


                el.find('a.js-destroy').data('id', id).data('fresh', true)
                $('#new_records tbody').append(el)
                $('#new_records').removeClass('hidden')

        enable: ->
                return if @enabled

                $('#bulk-panel').removeClass('hidden')
                $('#new_record .btn').attr('value', 'Bulk Add')
                $('#records .js-bulk-hide').hide()

                @enabled = true

        disable: ->
                return if !@enabled

                $('#bulk-panel').addClass('hidden')
                $('#inline-record-form .btn').attr('value', 'Add')
                $('#records .js-bulk-hide').show()
                @enabled = false

        commit: ->
                data = {
                        deletes: id for id, _ of @deletes,
                        changes: rec for id, rec of @changes when !@deletes[id] ,
                        additions: @additions
                }

                _me = this
                $.ajax {
                        url: @submit_url,
                        type: 'post',
                        data: JSON.stringify(data),
                        dataType: 'json',
                        contentType:'application/json',
                        success: (data) ->
                                console.log data
                        error: () ->
                                alert('There was an error submiting bulk operations')
                        }

        hook: ->
                return if @hooked

                _me = this
                # Hook bulky buttons
                $('#js-bulky-activate').click ->
                        _me.enable()
                        $(this).parents('li').remove()
                $('#js-bulky-cancel').click ->
                        _me.disable()
                $('#js-bulky-commit').click ->
                        _me.commit()
                $('#bulk-panel .js-modified-hover').hover \
                -> $('.modified').addClass('highlight')
                ,
                -> $('.modified').removeClass('highlight')
                
                # Hook destroy button
                $('#records, #new_records').on 'click', 'a.js-destroy', () ->
                        return true if !_me.enabled

                        link = $(this)
                        id = link.data('id')
                        fresh = link.data('fresh')

                        # Drop a newly created record
                        if fresh
                                delete _me.additions[id]
                                link.parents("#fresh-#{id}").remove()
                        # Resurrect a delete record
                        else if link.data('deleted')
                                delete _me.deletes[id]
                                link.data('deleted', false)
                                link.parents('tr').removeClass('danger')
                                link.parents('tr').attr('title', 'Remove')
                                link.find('span').removeClass('glyphicon-plus').addClass('glyphicon-remove')
                        # Delete a record
                        else
                                _me.deletes[id] = true
                                link.data('deleted', true)
                                link.parents('tr').addClass('danger')
                                link.find('abbr').attr('title', 'Undo') 
                                link.find('span').removeClass('glyphicon-remove').addClass('glyphicon-plus')

                        _me.panel_update()
                        return false;

                # Hook add button
                $('#new_record').submit () ->
                        return true if !_me.enabled

                        _me.validate_add $(this).serializeArray()
                        return false;
                @hooked = true

        debug: ->
                console.log("Bulky, enabled=#{@enabled}")
                for id, rec of @additions
                        change = for k, v of rec
                                "#{k}: #{v}"
                        console.log("Add #{id}: #{change}")
                for id, rec of @changes
                        change = for k, v of rec
                                "#{k}: #{v}"
                        console.log("Change #{id}: #{change}")
                for id, _ of @deletes
                        console.log("Delete #{id}")

