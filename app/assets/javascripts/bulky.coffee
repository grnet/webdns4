class window.Bulky
        constructor: (valid_record_url, submit_url) ->
                @enabled = false
                this.initValues()

                @valid_record_url = valid_record_url
                @submit_url = submit_url

                @hooked = false
                @hook()

        initValues: () ->
                @deletes   = {}
                @changes   = {}
                @additions = {}
                @add_counter = 0

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

        render_errors: (errors) ->
                if errors.deletes
                        deleted = ("#record-#{d}" for own d of errors.deletes)
                        txt = " (#{deleted.length} failed to delete)"
                        $('#bulk-panel .failed-deleted').text(txt).data(ids:deleted)
                if errors.changes
                        changed = ("#record-#{c}" for own c of errors.changes)
                        txt = " (#{changed.length} failed to be updated)"
                        $('#bulk-panel .failed-changed').text(txt).data(ids:changed)
                if errors.additions
                        added = ("#fresh-#{a}" for own a of errors.additions)
                        txt = " (#{added.length} failed to be added)"
                        $('#bulk-panel .failed-added').text(txt).data(ids:added)

        render_clear_errors: ->
                $('#bulk-panel .failed').text('')

        enable: ->
                return if @enabled

                # hide bulk mode button
                $('#js-bulky-activate').hide()
                # show bulk panel
                $('#bulk-panel').removeClass('hidden')
                # Change Add button
                $('#new_record .btn').attr('value', 'Bulk Add')
                # Hide disabled buttons for bulk mode
                $('#records .js-bulk-hide').hide()

                @enabled = true

        disable: ->
                return if !@enabled

                # hide the bulk panel
                $('#bulk-panel').addClass('hidden')
                # Revert add button to original value
                $('#inline-record-form .btn').attr('value', 'Add')
                # show the buttons that bulk mode hides
                $('#records .js-bulk-hide').show()
                # hide new records table
                $('#new_records').hide()
                # show bulk mode button
                $('#js-bulky-activate').show()

                # revert variables to initial values
                this.initValues()
                # update the panel to reflect the new values
                this.panel_update()
                @enabled = false

        commit: ->
                data = {
                        deletes: id for id, _ of @deletes,
                        # changes: rec for id, rec of @changes when !@deletes[id],
                        changes: @changes,
                        additions: @additions
                }
                @render_clear_errors()

                _me = this
                $.ajax {
                        url: @submit_url,
                        type: 'post',
                        data: JSON.stringify(data),
                        dataType: 'json',
                        contentType:'application/json',
                        success: (data) ->
                                console.log data
                                if data.errors
                                        _me.render_errors(data.errors)
                                        return
                                alert('Bulk operations successfully committed!')
                                location.reload()
                        error: () ->
                                alert('There was an error submiting bulk operations')
                        }

        hook: ->
                return if @hooked

                _me = this
                # Hook bulky buttons
                $('#js-bulky-activate').click ->
                        _me.enable()
                $('#js-bulky-cancel').click ->
                        _me.disable()
                $('#js-bulky-commit').click ->
                        _me.commit()
                $('#bulk-panel .js-modified-hover').hover \
                -> $('.modified').addClass('highlight')
                ,
                -> $('.modified').removeClass('highlight')

                $('#bulk-panel .failed').hover \
                -> $($(this).data('ids').join(', ')).addClass('highlight')
                ,
                -> $($(this).data('ids').join(', ')).removeClass('highlight')
                
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

