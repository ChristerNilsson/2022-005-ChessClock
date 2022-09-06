state = 0 

# 0 = paused (player in [-1,0,1])
#   player = -1 no button
#   player = 0 left button disabled
#   player = 1 right button disabled
#   PLAY
#   NEW

# 1 = not running (player==-1)
#   player = -1 both buttons
#   PAUSE

# 2 = running (player in [0,1])

# 3 = edit
#   OK

player = -1 # -1, 0=left, 1=right
clocks = [3*60,3*60] # sekunder med decimaler
bonuses = [2,2] # sekunder med decimaler

qr = null

editPage = null
mainPage = null
page = null

flip = () -> @value = 1 - @value
swap = () -> editPage.hcpSwap = -editPage.hcpSwap

left = -> add 0
right = -> add 1
add = (p) ->
	#if state == 1
		#state = 2
	console.log clocks[player], bonuses[player]
	clocks[player] += bonuses[player]
	console.log clocks[player], bonuses[player]
	player = p
	mainPage.buttons['pause'].visible = true

edit = -> 
	if state == 0
		state = 3
		page = editPage

pause = ->
	if state in [1,2] then state = 0 
	mainPage.buttons['play'].visible = true
	mainPage.buttons['pause'].visible = false

ok = -> 
	state = 0
	page = mainPage
	clocks[0]  = editPage.players[0][0]
	clocks[1]  = editPage.players[1][0]
	bonuses[0] = editPage.players[0][1]
	bonuses[1] = editPage.players[1][1]
	player = -1

class MainPage
	constructor : ->
		@buttons = {}
		w = width
		h = height
		@buttons['left'] =  new MainButton 0,  0.5*w,0.25*h,0.83*w,0.18*h, left,  true
		@buttons['right'] = new MainButton 1,  0.5*w,0.75*h,0.83*w,0.18*h, right, true
		@buttons['play'] =  new Button 'play', 0.1*w,0.50*h,0.17*w,0.11*h, pause, true,  true
		@buttons['pause'] = new Button 'pause',0.3*w,0.50*h,0.17*w,0.11*h, pause, false, true
		@buttons['new'] =   new Button 'new',  0.8*w,0.50*h,0.17*w,0.11*h, edit,  true,  true
		@buttons['left'].upsidedown = true

	draw : ->
		push()
		background 'black'
		@buttons[key].draw() for key of @buttons
		if state == 2 and clocks[player] > 0
			clocks[player] -= 1/60
			if clocks[player] < 0 then clocks[player] = 0
		pop()
		size = 0.11*height
		if qr then image qr,(width-size)/2,(height-size)/2,size,size
		fill 'white'
		textSize 0.05 * height
		if bonuses[0] > 0
			push()
			translate width/2,height/2-0.13*height
			rotate 180
			text '+'+round3(bonuses[0])+'s',0,0
			pop()
			text '+'+round3(bonuses[1])+'s',width/2,height/2+0.13*height

	mouseClicked : ->
		for key of @buttons
			button = @buttons[key]
			if not button.inside mouseX,mouseY then continue
			if key in ['left','right'] then button.click()

			if state==0
				if key=='play' 
					state = if player == -1 then 1 else 2
					@buttons['play'].visible = false
					@buttons['pause'].visible = true
					@buttons['new'].visible = false
				if key=='new' then button.click()
				return
			if state==1
				if key=='left'
					player = 1
					state = 2
				if key=='right'
					player = 0
					state = 2
				if key=='pause'
					state = 0
					@buttons['play'].visible = true
					@buttons['pause'].visible = false
					@buttons['new'].visible = true
				return
			if state==2
				if key=='left'
					player = 1
				if key=='right'
					player = 0
				if key=='pause'
					state=0  
					@buttons['play'].visible = true
					@buttons['pause'].visible = false
					@buttons['new'].visible = true
				return
				# if key=='play'
				# 	state=0 
				# 	@buttons['play'].enabled = true
				# 	@buttons['pause'].enabled = false
				# 	@buttons['new'].enabled = true

class EditPage
	constructor : ->
		@matrix = []
		yoff = 0.08 * height
		for j in range 6
			headers = 'h m s m s t'.split ' '
			cells = []
			x = 0.17 * width + j*0.13 * width
			dy = 0.09 * height
			cells.push new EditButton headers[j],x,yoff+2*dy,flip,false
			cells.push new EditButton 1,         x,yoff+3*dy,flip,true
			cells.push new EditButton 2,         x,yoff+4*dy,flip,true
			cells.push new EditButton 4,         x,yoff+5*dy,flip,true
			cells.push new EditButton 8,         x,yoff+6*dy,flip,true
			cells.push new EditButton 15,        x,yoff+7*dy,flip,true
			cells.push new EditButton 30,        x,yoff+8*dy,flip,true
			@matrix.push cells

		# ställ in 3m+2s (default)
		@matrix[1][1].value = 1
		@matrix[1][2].value = 1
		@matrix[4][2].value = 1

		# ställ in 3h+2m (default)
		# @matrix[0][1].value = 1
		# @matrix[0][2].value = 1
		# @matrix[3][2].value = 1

		@buttons = []
		w = width
		h = height
		@buttons.push new Button 'ok',  0.5*w, 0.89*h, 0.17*w, 0.04*h, ok,   true,true
		@buttons.push new Button 'swap',0.5*w, 0.08*h, 0.17*w, 0.04*h, swap,true,true

		@sums = [0,0,0,0,0,0]
		@hcpSwap = 1

	draw : ->
		push()
		background 'black'

		fill 'white'
		textSize 0.05 * height
		text 'reflection',0.30*width, 0.18*height
		text 'bonus',     0.63*width, 0.18*height
		text 'hcp',       0.83*width, 0.18*height

		fill 'white'
		textSize 0.03*height
		headers = 'h m s m s t'.split ' '
		@sums = [0,0,0,0,0,0]
		for button in @buttons
			button.draw()
		for i in range @matrix.length
			cells = @matrix[i]
			for j in range cells.length
				button = cells[j]
				button.draw()
				if j != 0 then @sums[i] += button.text * button.value
		@buttons[0].visible = @sums[0] + @sums[1] + @sums[2] > 0

		header0 = ''
		header1 = ''
		for i in range 0,3
			if @sums[i]>0 then header0 += @sums[i] + headers[i]
		for i in range 3,5
			if @sums[i]>0 then header1 += @sums[i] + headers[i]
		header = header0
		if header1.length > 0 then header += ' + ' + header1

		@hcp = @hcpSwap * @sums[5]/60 # 0.0 .. 1.0
		@refl = 3600 * @sums[0] + 60 * @sums[1] + @sums[2] # sekunder
		@bonus =                  60 * @sums[3] + @sums[4] # sekunder
		@players = []
		@players[0] = [@refl*(1+@hcp), @bonus*(1+@hcp)]
		@players[1] = [@refl*(1-@hcp), @bonus*(1-@hcp)]

		y = 0.08 * height
		if @sums[5] == 0 # inget handicap
			@buttons[1].visible = false
			fill 'white'
			textSize 0.07*height
			text header, 0.5*width,y
		else # handicap
			@buttons[1].visible = true
			fill 'red'
			textAlign LEFT,CENTER
			left   = pretty(@players[0][0]) + ' + ' + pretty(@players[0][1])
			text left, 0,y-0.04*height

			fill 'green'
			textAlign RIGHT,CENTER
			right  = pretty(@players[1][0]) + ' + ' + pretty(@players[1][1])
			text right, width,y+0.04*height
		pop()

	mouseClicked : ->
		for button in @buttons
			if button.inside mouseX,mouseY then button.click()
		for cells in @matrix
			for button in cells
				if button.visible and button.inside mouseX,mouseY then button.click()

round3 = (x) -> Math.round(x*1000)/1000

pretty = (tot) ->
	s = tot % 60
	tot = (tot - s) / 60
	m = tot % 60
	tot = (tot - m) / 60
	h = tot % 60
	header = ''
	if h>0 then header += round3(h) + 'h'
	if m>0 then header += round3(m) + 'm'
	if s>0 then header += round3(s) + 's'
	header

d2 = (x) ->
	x = Math.trunc x
	if x < 10 then '0'+x else x
console.log d2(3), '03'

hms = (x) ->
	s = x %% 60
	x = x // 60
	m = x %% 60
	x = x // 60
	h = x
	[h,m,s]
console.log hms(180), [0,3,0]

###############################

class Button
	constructor : (@text,@x,@y,@width,@height,@click,@visible=true,@rect=true) ->
	draw : ->
		if not @visible then return 
		if @rect
			fill 'white'
			rect @x,@y,@width,@height
			fill 'black'
		else
			fill 'white'
		textSize 0.04*height
		text @text,@x,@y

	inside : (mx,my) -> @x-@width/2 < mx < @x+@width/2 and @y-@height/2 < my < @y+@height/2

class EditButton extends Button
	constructor : (text,x,y,click,visible) ->
		super text,x,y,0.05*width,0.03*height,click,visible
		@value = 0

	draw : ->
		fill ['gray','yellow'][@value]
		textSize 0.04*height
		text @text,@x,@y

class MainButton extends Button
	constructor : (@player,x,y,width,height,click,visible) ->
		super "",x,y,width,height,click,visible

	draw : ->
		secs = clocks[@player]
		if secs == 0 then fill 'red'
		[h,m,s] = hms Math.trunc secs
		ss = if h >= 1 then d2(h) + ':' + d2(m) else d2(m) + ':' + d2(s)

		fill if @visible then 'white' else "black"
		if state in [1,2] and player in [-1,@player]
			rect @x,@y,@width,@height
			fill if @visible then 'black' else "white"

		push()
		translate @x,@y
		if @upsidedown then rotate 180
		textSize 0.22*height
		text ss,0,0.017*height
		pop()

draw = -> 
	page.draw()

	push() # DEBUG!
	fill 'gray'
	textSize 0.03*height
	text round3(clocks[0]), 0.2 * width, 0.95 * height
	text "S:#{state}",      0.4 * width, 0.95 * height
	text Math.round(frameRate()), 0.5 * width, 0.95 * height
	text "P:#{player}",     0.6 * width, 0.95 * height
	text round3(clocks[1]), 0.8 * width, 0.95 * height
	pop()

preload = -> qr = loadImage 'qr.png'

setup = ->
	createCanvas innerWidth,innerHeight
	textAlign CENTER,CENTER
	rectMode CENTER
	angleMode DEGREES
	editPage = new EditPage()
	mainPage = new MainPage()
	page = mainPage

mouseClicked = -> page.mouseClicked()
