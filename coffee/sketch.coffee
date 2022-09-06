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

editPage = null
mainPage = null
page = null

flip = () -> @value = 1 - @value
swap = () -> editPage.hcpSwap = -editPage.hcpSwap

left = -> 
	if state == 0 then return 
	if state == 1
		state = 2
		clocks[player] += bonuses[player]
		player = 0
		mainPage.buttons['pause'].visible = true

right = ->
	if state == 0 then return 
	if state == 1
		state = 2
		clocks[player] += bonuses[player]
		player = 1
		mainPage.buttons['pause'].visible = true

	# if state in [-2,2] then return
	# state = 2
	# clocks[player] += bonuses[player]
	# player = 0
	# mainPage.buttons['pause'].enabled = true

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
		@buttons['left'] =  new ButtonTime 0,120,40,230,60,left,true
		@buttons['right'] = new ButtonTime 1,width-120,40,230,60,right,true
		@buttons['play'] =  new Button 'play',250,100+40,100,40, pause, true, true
		@buttons['pause'] = new Button 'pause',250,100+100,100,40, pause, false, true
		@buttons['new'] =   new Button 'new',500,100+40,100,40, edit, true, true

	draw : ->
		push()
		background 'black'
		rectMode CENTER
		textAlign CENTER,CENTER
		@buttons[key].draw() for key of @buttons
		if state == 2 and clocks[player] > 0 then clocks[player] -= 1/60
		pop()

	mouseClicked : ->
		for key of @buttons
			button = @buttons[key]
			if not button.inside mouseX,mouseY then continue

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
		yoff = 30
		for j in range 6
			headers = 'h m s m s t'.split ' '
			cells = []
			x = 50+j*60
			dy = 40
			cells.push new TimeButton headers[j],x,yoff+2*dy,flip,false
			cells.push new TimeButton 1,         x,yoff+3*dy,flip,true
			cells.push new TimeButton 2,         x,yoff+4*dy,flip,true
			cells.push new TimeButton 4,         x,yoff+5*dy,flip,true
			cells.push new TimeButton 8,         x,yoff+6*dy,flip,true
			cells.push new TimeButton 15,        x,yoff+7*dy,flip,true
			cells.push new TimeButton 30,        x,yoff+8*dy,flip,true
			@matrix.push cells

		# ställ in 3m+2s (default)
		@matrix[1][1].value = 1
		@matrix[1][2].value = 1
		@matrix[4][2].value = 1

		@buttons = []
		@buttons.push new Button 'ok',500,350,100,40,ok,true,true
		@buttons.push new Button 'swap',width/2,30,100,40,swap,true,true

		@sums = [0,0,0,0,0,0]
		@hcpSwap = 1

	draw : ->
		push()
		background 'black'

		fill 'white'
		textSize 32
		text 'reflection',45,90
		text 'bonus',212,90
		text 'hcp',325,90

		fill 'white'
		textSize 20
		rectMode CENTER
		textAlign CENTER,CENTER
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
		header = ''
		for i in range 6
			if @sums[i]>0 then header += @sums[i] + headers[i]
			if i==2 then header += ' + '

		@hcp = @hcpSwap * @sums[5]/60 # 0.0 .. 1.0
		@refl = 3600 * @sums[0] + 60 * @sums[1] + @sums[2] # sekunder
		@bonus =                  60 * @sums[3] + @sums[4] # sekunder
		@players = []
		@players[0] = [@refl*(1+@hcp), @bonus*(1+@hcp)]
		@players[1] = [@refl*(1-@hcp), @bonus*(1-@hcp)]

		y = 30
		if @sums[5] == 0 # inget handicap
			@buttons[1].visible = false
			fill 'white'
			text header, width/2,y
		else # handicap
			@buttons[1].visible = true
			fill 'red'
			textAlign LEFT,CENTER
			left   = pretty(@players[0][0]) + ' + ' + pretty(@players[0][1])
			text left, 0,y

			fill 'green'
			textAlign RIGHT,CENTER
			right  = pretty(@players[1][0]) + ' + ' + pretty(@players[1][1])
			text right, width,y
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
		textSize 32
		text @text,@x,@y

	inside : (mx,my) -> @x-@width/2 < mx < @x+@width/2 and @y-@height/2 < my < @y+@height/2
	click : -> @click()

d2 = (x) ->
	x = Math.round x
	if x < 10 then "0" + x
	else x

class TimeButton extends Button # within EditPage
	constructor : (text,x,y,click,visible) ->
		super text,x,y,30,30,click,visible
		@value = 0

	draw : ->
		fill ['gray','yellow'][@value]
		textSize 32
		textAlign CENTER,CENTER
		text @text,@x,@y
		fill ['gray','yellow'][@value]
		textSize 32
		textAlign CENTER,CENTER
		text @text,@x,@y

class ButtonTime extends Button # within MainPage
	constructor : (@player,x,y,width,height,click,visible) ->
		super "",x,y,width,height,click,visible

	draw : ->
		textSize 60
		if state in [1,2] and player==-1 or player==@player
			fill if @visible then 'white' else "black"
			rect @x,@y,@width,@height
			fill if @visible then 'black' else "white"
		else
			fill if @visible then 'white' else "black"
		s = clocks[@player]
		#fill 'black'
		text d2(s // 3600),@x-80,@y
		text ':',@x-40,@y
		text d2(s // 60),@x+0,@y
		text ':',@x+40,@y
		text d2(s %% 60),@x+80,@y

	click : -> @click()

draw = -> 
	push()
	page.draw()

	fill 'white' # DEBUG!
	textSize 32
	textAlign CENTER,CENTER
	text "state:#{state}",  0.85*width,height/2
	text "player:#{player}",0.85*width,height/2+50
	pop()

setup = ->
	createCanvas 600,400
	editPage = new EditPage()
	mainPage = new MainPage()
	page = mainPage

mouseClicked = -> page.mouseClicked()
