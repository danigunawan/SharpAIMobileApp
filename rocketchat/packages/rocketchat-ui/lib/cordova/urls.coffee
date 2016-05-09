Meteor.startup ->
	$(document).on 'click', (e) ->
		if e.target.type isnt 'textarea' and e.target.type isnt 'input'
			window.parent.postMessage('closekeyboard', '*');
	
	return unless Meteor.isCordova

	# Handle click events for all external URLs
	$(document).on 'deviceready', ->
		platform = device.platform.toLowerCase()
		$(document).on 'click', (e) ->
			$link = $(e.target).closest('a[href]')
			return unless $link.length > 0
			url = $link.attr('href')

			if /^https?:\/\/.+/.test(url) is true
				window.open url, '_system'
				e.preventDefault()
