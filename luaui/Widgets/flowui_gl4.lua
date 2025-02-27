

function widget:GetInfo()
	return {
		name      = 'FlowUI GL4 Tester',
		desc      = 'FlowUI GL4 Testing',
		author    = 'Beherith',
		version   = '1.0',
		date      = '2021.05.020',
		license   = 'Lua code: GNU GPL, v2 or later; GLSL code: (c) Beherith mysterme@gmail.com',
		layer     = 100,
		enabled   = false,  --  loaded by default?
	}
end

local glLineWidth = gl.LineWidth
local glDepthTest = gl.DepthTest
local GL_LINES = GL.LINES
local chobbyInterface
local font
local rectRoundVBO = nil
local vsx, vsy = Spring.GetViewGeometry()
local groups = {} -- {energy = 'LuaUI/Images/groupicons/'energy.png',...}, retrieves from buildmenu in initialize
local unitGroup = {}	-- {unitDefID = 'energy'}retrieves from buildmenu in initialize
local unitIcon = {}	-- {unitDefID = 'icons/'}, retrieves from buildmenu in initialize

--- OO stuff
-- Each uielement should have a parent, and can have any number of childrent
-- A uiElement may consist of any combination of geometric primitives
-- A uiElement may have a table of fonts assigned to it
-- Should have a known position, and maybe even have its own highlight instance
-- A uielement can be deleted, which will result in the deletion of all of its children
-- an element can be hidden, which will also hide all of its children
-- an element can be shown, which will show all of its children
	-- this is bad because of highlighting

-- element data members:
	
	-- flatprimitives{} -- an array of VBO keys
	-- blendedprimitives{} -- an array of VBO keys
	-- TextElements{} -- this one is kinda hard, but well figure it out
	-- bool mousehits()
		-- A nice recursive call, 

	-- bool visible 

-- element functions:

	-- Hide() 
		-- hides self and all children
	-- Show()
		-- shows self and all children
	-- Toggle()
		-- inverts self, and sets all children to it
	-- Remove()
		-- deletes all children and self
		
	-- Update()
		-- Should update its own primitives (probably by deleting and recreating them)
		-- 
	-- Mouseover()
		-- a function on what to do when mouse is over it
	-- OnClick()
		-- 
	-- AddChild()
	-- RemoveChild()
	-- GetChildByName()


-- element 'Callbacks'
	
	
-- Draw Implementation
-- the Z depth of any element must be greater than its childrens
-- We need 2 separate VBOS, for flat blended and alpha blended stuff. Draw the flat first, then the alpha blended one
-- we need a manager for all text type UI elements, consider replacing as much text as posssible with textures!
-- Only textures that are actually in the atlas are renderable
-- the atlas is built once, and queried

-- We can entirely avoid alpha blended, if we specify a 'highlighttexture' and a blendfactor



-- Notes from 2022.10.21 ---------------------------------------------------------
-- We can ignore the WHOLE blendedprimitives shit from above because of in-shader highlighting!
-- WHERE IS THE ORIGIN IN SCREENSPACE: BOTTOM LEFT!
-- what if we just went the array table way?
local Draw = {}
local vsx, vsy = 1920, 1024
local nameCounter = 0
local ROOT
local floor = math.floor
-- what if I enabled LEFT, RIGHT, TOP, BOTTOM? 
-- and calced X,Y, W,H from it?

local metaElement = {
} 

-- This will be the base metatable, and contains the functions and static members that we want
local metaElement_mt = { 
	__index = metaElement,
	vsx = vsx,
	vsy = vsy,
	vbokeys = {left = 1, bottom = 2, right=3, top = 4, tl = 5, tr = 6, br = 7, bl = 8,
		color1r = 9, color1g = 10, color1b = 11, color1a = 12, color2r = 13, color2g = 14, color2b = 15, color2a = 16,
		uvbottom = 17, uvleft = 18, uvtop = 19, uvright = 20, 
		fronttexture = 21, edge = 22, zdepth = 23, progress = 24,
		hide = 25, blendmode = 26, globalbg = 27, unused = 28,
	},
	currtextcolor = {1,1,1,1},
	curroutlinecolor = {0,0,0,1},
}

local function newElement(o) -- This table contains the default properties 
	if o == nil then o = {} end 
	if o.name == nil then -- auto namer
		nameCounter = nameCounter + 1
	end
	
	local element =   {
		name = o.name or 'element'..tostring(nameCounter),
		left = x or 0,
		bottom = y or 0,
		right = w or vsx, 
		top = h or vsy,
		depth = depth or 0.5, -- halfway?
		treedepth = 1, -- how deep we are in the render tree
		onclick = {},
		--self.childern = {},
		--textelements = {}, 
		--visible = true, 
		--clickable = false,
		--parent = ROOT,
		--instanceKeys = {}, -- a table of the instancekeys corresponding to this piece of shit
	}
	
	local obj = setmetatable(element, metaElement_mt)
	for k,v in pairs(o) do obj[k] = v end 
	
	if not obj.root then 
		local parent = obj.parent or ROOT

		if parent.children == nil then 
			parent.children = {[obj.name] = obj}
		else
			parent.children[obj.name] = obj
		end
	end
	return obj
end

-- Get the 'smallest' element of the chain that is 'hit' 
function metaElement:MouseOver(mx,my) 
	print (self)
	local hit = false
	if mx <= right and mx >= left and my <= top and my >= bottom then hit = true end
	if hit == false then return nil 
	else 
		if self.children then 
			for childname, childElement in pairs(self.children) do 
				if childElement:MouseOver(mx,y) then
					return childElement
				end
			end
		end
		return self -- no children were 'hit'
	end
end

function metaElement:UpdateTextPosition(text)
	-- todo fix alignment
end

-- Note that this takes 
-- aligment can be any of ['top', 'left','bottom','right', 'center', 'topleft', ]
function metaElement:AddText(ox, oy, text, fontsize, textoptions, alignment, textcolor, outlinecolor)
	-- it is now that we need to cache text height, and width
	local newtext = {
			ox = ox, -- offset from bottom left corner 
			oy = oy,
			text = text,
			fontsize = fontsize or 16,
			textoptions = textoptions or "",
			textcolor = textcolor,
			outlinecolor = outlinecolor,
			alignment = alignment,
		}

	newtext.textwidth  = font:GetTextWidth(text)  * newtext.fontsize
	newtext.textheight = font:GetTextHeight(text) * newtext.fontsize

	
	if self.textelements == nil then self.textelements = {} end 
	self.textelements[#self.textelements + 1] = newtext
	self:UpdateTextPosition(newtext)
	return #self.textelements
end

function metaElement:RemoveText(textindex)
	if self.textelements then 
		return table.remove(self.textelements, textindex)
	end
end

function metaElement:DrawText(px,py) -- parentx,parenty
	--Spring.Echo(self)
	if self.textelements then 
		for i, text in ipairs(self.textelements) do
			font:Print(text.text, text.ox + self.left, text.oy + self.bottom, text.fontsize, text.textoptions)
			--Spring.Echo(text.text,text.ox, px, text.oy, py)
		end
	end
	if self.children then
		for name, child in pairs(self.children) do 
			child:DrawText(self.left, self.bottom)
		end
	end
end


function metaElement:Click(mx,my, clicktype)
	local hit = false
	self.x = 1
	--Spring.Echo("Testing",self.name, self.left,self.right,self.top,self.bottom)
	if mx >= self.left and mx <= self.right and my <= self.top and my >= self.bottom then hit = true end
	--Spring.Echo("result:",hit)
	if hit == false then return nil 
	else 
		--Spring.Echo("Testing",self.name, self.left,self.right,self.top,self.bottom)
		if self.children then 
			for childname, childElement in pairs(self.children) do 
				if childElement:Click(mx,my,clicktype) then
					return childElement
				end
			end
		end
		for click, val in pairs(clicktype) do 
			if self.onclick[click] then 
				Spring.Echo("Clicked", self.name)
				self.onclick[click]()
			end
		end
		return self -- no children were 'hit'
	end
	
end

function metaElement:CalculatePosition()
	-- to automatically do top left bototm right and percentage values
	-- also check if it changed, and then update it in vbo maybe?
end

function metaElement:NewContainer(o)
	return newElement(o)
end

function metaElement:NewButton(o) -- yay this objs shit again!
	local obj = newElement(o)
	
	--parent, VBO, instanceID, z,px, py, sx, sy,  tl, tr, br, bl,  ptl, ptr, pbr, pbl,  opacity, color1, color2, bgpadding)
	obj.instanceKeys = Draw.Button( rectRoundVBO or obj.VBO, obj.name, obj.depth, obj.left, obj.bottom, obj.right, obj.top,  
		obj.tl or 1, obj.tr or 1, obj.br or 1, obj.bl or 1,  obj.ptl or 1, obj.ptr or 1, obj.pbr or 1, obj.pbl or 1,  obj.opacity or 1, 		obj.color1, obj.color2, obj.bgpadding or 3)
	return obj
	
end

function metaElement:NewCheckBox(obj) end
function metaElement:NewSelector(obj) end
function metaElement:NewSlider(obj) end
function metaElement:NewUiUnit(o) 
	local obj = newElement(o)
	
	obj.instanceKeys = Draw.Unit(rectRoundVBO or obj.VBO, obj.name, obj.depth, obj.left, obj.bottom, obj.right,obj.top,  
			obj.cs, obj.tl or 1, obj.tr or 1, obj.br or 1, obj.bl or 1,  obj.zoom or 1, obj.bordersize ,0.8, --zoom,  borderSize, borderOpacity
			obj.texture,
			obj.radartexture,
			obj.grouptexture,
			obj.price,
			obj.queueCount
		)
	
			--Draw.Unit = function(VBO, instanceID, z, px, py, sx, sy,  cs,  tl, tr, br, bl,  zoom,  borderSize, borderOpacity,  texture, radarTexture, groupTexture, price, queueCount)
			--Draw.Unit(rectRoundVBO, nil, 0.5, x,y,w,y+2*s, 20, 
			--1,1,1,1,
			--1, nil, 0.8, -- zoom, bordersize, borderOpacity
			--"unitpics/corcom.dds", 
			--"icons/bantha.png",
			--"luaui/images/flowui_gl4/metal.png", --grouptexture
			--500, 7)
	end
function metaElement:NewRectRound(obj) end
function metaElement:NewEmpty(obj) end

local testElement = {
	name = 'test',
	left = 0, -- could be string types? As those can be parsed quite quick for percentage
	right = 0,
	top = 0, 
	bottom = 0,
	instanceKeys = {},
	children = {},
	textelements = {},
	--onclick = {left, right, middle, double }
	--MouseOver = 
}

ROOT = metaElement:NewContainer({root = true})
local clickcache = {}
local lasthitelement = nil -- this is to store which one was last hit to fire off mouseentered mouseleft events 
-- TODO: debounce clicking!
local function uiUpdate(mx,my,left,middle,right)
	-- this needs to be revamped, to trace the element under cursor, and then act based on clickedness
	local clicked = left or middle or right
	if left then clickcache.left = true else clickcache.left = nil end 
	if middle then clickcache.middle = true else clickcache.middle = nil end 
	if right then clickcache.right = true else clickcache.right = nil end 
	if clicked then 
		ROOT:Click(mx,my,clickcache)
	end
end

local dlist = nil
local function DrawText()
	if false then 
		if dlist == nil then 
			dlist = gl.CreateList(function () 
			font:Begin()
			ROOT:DrawText(0,0)
		--font:SubmitBuffered(true) 
			font:End()
			end
			)
		else
			gl.CallList(dlist)
		end

	else
		font:Begin()
		ROOT:DrawText(0,0)
		--font:SubmitBuffered(true) 
		font:End()
	end
end
---
local function makebuttonarray()
	for i = 1, 10 do
		for j = 1, 10 do 
			--rectRoundVBO, nil, 0.4, x,y,w,h, 1,1,1,1, 1,1,1,1, nil, { 0, 0, 0, 0.8 }, {0.2, 0.8, 0.2, 0.8 }, WG.FlowUI.elementCorner * 0.5
			local newbtn = metaElement:NewButton({
					left = 100 + 100*i,
					bottom = 300 + 50 *j,
					right = 190 + 100*i,
					top = 340 + 50 *j,
					parent = ROOT,
					onclick = {left = function() Spring.Echo("left clicked",i,j) end},
					textelements = {{text = "mytext"..tostring(i).."-"..tostring(j),ox = 0, oy= 16,fontsize = 16,textoptions = 'nB'},},
					
				})
			
			
		end
	end
end

local function makeunitbuttonarray()
	-- what can my boy build?
	local unitDef = UnitDefs[UnitDefNames['armcom'].id]
	for k,v in pairs(unitDef.buildOptions) do
		Spring.Echo(k,v)
	end
	for i = 1, 10 do
		for j = 1, 10 do 
			--rectRoundVBO, nil, 0.4, x,y,w,h, 1,1,1,1, 1,1,1,1, nil, { 0, 0, 0, 0.8 }, {0.2, 0.8, 0.2, 0.8 }, WG.FlowUI.elementCorner * 0.5
			local idx = ((i-1)*10+j) % (#unitDef.buildOptions) + 1
			if unitDef.buildOptions[idx] then 
				local thisunitdefid = unitDef.buildOptions[idx]
				local newbtn = metaElement:NewUiUnit({
						left = 1000 + 100*i,
						bottom = 100 + 100 *j,
						right = 1100 + 100*i,
						top = 200 + 100 *j,
						parent = ROOT,
						texture = 'unitpics/'.. UnitDefs[thisunitdefid].name ..'.dds',
						radartexture = unitIcon[thisunitdefid],
						grouptexture = groups[unitGroup[thisunitdefid]],
						onclick = {left = function() Spring.Echo("left clicked unit",i,j) end},
						textelements = {{text = unitDef.name,ox = 0, oy= 0,fontsize = 16,textoptions = 'nB'},},
						
					})
			else
				break
			end
				
				
			
		end
	end
end
local start = collectgarbage("count")
--makebuttonarray()
start = collectgarbage("count") - start
print ("yay", start)
local brk = 0
print ("end")
----------------------------------------------------------------
-- GL4 STUFF
----------------------------------------------------------------

local luaShaderDir = "LuaUI/Widgets/Include/"
local LuaShader = VFS.Include(luaShaderDir.."LuaShader.lua")
VFS.Include(luaShaderDir.."instancevbotable.lua")
local rectRoundShader = nil
local rectRoundVAO = nil
local vsx,vsy = gl.GetViewSizes()
local atlasID = nil
local atlassedImages = {}
--local rectRoundVBO = nil

local vsSrc = [[
#version 420
#line 5000

#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shading_language_420pack: require
//__ENGINEUNIFORMBUFFERDEFS__

layout (location = 0) in vec4 screenpos; // left, bottom, right, top, in pixels
layout (location = 1) in vec4 cornersizes; // tl, tr, br, bl
layout (location = 2) in vec4 color1; // rgba
layout (location = 3) in vec4 color2; // rgba
layout (location = 4) in vec4 uvoffsets; // uvrect, bottom left, top right
layout (location = 5) in vec4 fronttexture_edge_z_progress; //  textured, edgewidth, z,progress
layout (location = 6) in vec4 hide_blendmode_globalbackground;;  

out DataVS {
	vec4 v_screenpos;
	vec4 v_cornersizes;
	vec4 v_color1;
	vec4 v_color2;
	vec4 v_uvoffsets;
	vec4 v_fronttexture_edge_z_progress;
	vec4 v_hide_blendmode_globalbackground;
};

#line 5100
void main() {
	gl_Position = vec4(screenpos.x, 0, screenpos.y,1.0);
	v_screenpos = screenpos;
	v_cornersizes = cornersizes;
	v_color1 = color1;
	v_color2 = color2;
	v_uvoffsets = uvoffsets;
	v_fronttexture_edge_z_progress = fronttexture_edge_z_progress;
	v_hide_blendmode_globalbackground = hide_blendmode_globalbackground;
}
]]

local gsSrc = [[
#version 330

#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shading_language_420pack: require

layout (points) in;
layout (triangle_strip, max_vertices = 32) out; // 9 tris * 3


//__ENGINEUNIFORMBUFFERDEFS__

#line 20000
in DataVS {
	vec4 v_screenpos;// left, bottom, right, top, in pixels
	vec4 v_cornersizes;
	vec4 v_color1;
	vec4 v_color2;
	vec4 v_uvoffsets;
	vec4 v_fronttexture_edge_z_progress;
	vec4 v_hide_blendmode_globalbackground;
} dataIn[];

out DataGS {
	vec4 g_screenpos;
	vec4 g_uv; // should also contain 'background texture shit'
	vec4 g_color;
	vec4 g_color2;
	vec4 g_fronttex_edge_backtex_hide;
};



#define TL_CORNERSIZE dataIn[0].v_cornersizes.x
#define TR_CORNERSIZE dataIn[0].v_cornersizes.y
#define BR_CORNERSIZE dataIn[0].v_cornersizes.z
#define BL_CORNERSIZE dataIn[0].v_cornersizes.w

#define LEFT dataIn[0].v_screenpos.x
#define BOTTOM dataIn[0].v_screenpos.y
#define RIGHT dataIn[0].v_screenpos.z
#define TOP dataIn[0].v_screenpos.w

#define UV dataIn[0].v_uvoffsets

#define PROGRESS dataIn[0].v_fronttexture_edge_z_progress.w
#define EDGE dataIn[0].v_fronttexture_edge_z_progress.y
#define DEPTH dataIn[0].v_fronttexture_edge_z_progress.z
#define FRONTTEXTURE dataIn[0].v_fronttexture_edge_z_progress.y

#define HIDE dataIn[0].v_hide_blendmode_globalbackground.x
#define BLENDMODE dataIn[0].v_hide_blendmode_globalbackground.y
#define BACKTEXTURE dataIn[0].v_hide_blendmode_globalbackground.z

void addvertexflowui(float spx, float spy, float distfromside){
	g_screenpos = vec4(spx, spy, DEPTH, 1.0);
	g_uv.x = UV.x + (UV.z - UV.x)*((spx - LEFT) /(RIGHT - LEFT));// horz of maintexture
	g_uv.y = UV.y + (UV.w - UV.y)*((spy - BOTTOM)/(TOP - BOTTOM));// vert of maintexture

	g_screenpos.xy = (g_screenpos.xy / viewGeometry.xy)* 2.0 - 1.0; // viewGeometry.xy contains view size in pixels
	
	g_uv.z = spx; // world uv coords for global background
	g_uv.w = spy; // world uv coords for global background
	
	float topness = (spy - BOTTOM)/(TOP - BOTTOM); // top is 1, bottom is 0
	
	g_color = mix(dataIn[0].v_color1, dataIn[0].v_color2, topness);
	
	g_fronttex_edge_backtex_hide = dataIn[0].v_fronttexture_edge_z_progress;
	
	float future_feather = 200.0;
	if (EDGE > 0.5 ) {
		float borderwidth1_0 =  distfromside - EDGE ; // 50 - 10
		future_feather = distfromside / borderwidth1_0; // WIP 50 / (50-10)
		
		//future_feather = (1.0 / EDGE) * (distfromside 
		if (distfromside > 1.0) {
			future_feather = -1.0 * distfromside/EDGE;
		}
		else {
			future_feather = 1.0;
		}
		g_color2 = mix(dataIn[0].v_color1, dataIn[0].v_color2, future_feather);
	}else{
		//g_fronttex_edge_backtex_hide.y = 200.0 ;
		g_color2 = vec4(1.0, 0.0, 1.0 , 1.0);
	}
	g_fronttex_edge_backtex_hide.y = future_feather;
	
	// pack mouseposness into 'backtex', ergo g_fronttex_edge_backtex_hide.z
	g_fronttex_edge_backtex_hide.z = 0.0;
	bvec2 righttopmouse = lessThan(mouseScreenPos.xy, vec2(RIGHT, TOP));
	bvec2 leftbottommouse = greaterThan(mouseScreenPos.xy, vec2(LEFT, BOTTOM));
	g_fronttex_edge_backtex_hide.z = 0;
	if (all(bvec4(righttopmouse, leftbottommouse)) ) {
		g_fronttex_edge_backtex_hide.z = BLENDMODE + 0.5;	
		// also pack clickedness into this //	uint mouseStatus; // bits 0th to 32th: LMB, MMB, RMB, offscreen, mmbScroll, locked
		if ((mouseStatus & 1u) > 0u){
			g_fronttex_edge_backtex_hide.z += BLENDMODE + 0.5;
		}
	}
	

	
	g_fronttex_edge_backtex_hide.w = HIDE;
	
	gl_Position = vec4(g_screenpos.x, g_screenpos.y, DEPTH, 1.0);
	
	g_screenpos = vec4(spx, spy, DEPTH, 1.0);
	EmitVertex();
}


#define HALFPI 1.570796326794896

#define PI 3.1415926535897932384626433832795

#define TWOPI 6.283185307179586476925286766559

float centerx;
float centery;


#line 20149
void main() {
	vec4 gs_cornersizes = dataIn[0].v_cornersizes;

	// for progress angles, we will be idiots and only calc it for zero corners

	float invprogress = 1.0-PROGRESS; // at a PROGRESS of 30%, we want to draw the last 70% of the element
	float progress_offset;
	// a progress of 90% means an invprogress of 10%, so we 
	float centery = (TOP + BOTTOM) * 0.5;
	float centerx = (LEFT + RIGHT) * 0.5;
	float distfromside = (TOP - BOTTOM) * 0.5;
	
	// TOPRIGHT side
	if (invprogress<0.125) {
		progress_offset = (RIGHT-LEFT - TR_CORNERSIZE) * clamp((invprogress - 0.0) * 4, 0, 1.0);
		
		addvertexflowui(centerx, centery, distfromside); //center vertex:
		addvertexflowui(RIGHT - TR_CORNERSIZE, TOP, 0.0);
		addvertexflowui(centerx + progress_offset , TOP, 0.0);
		EndPrimitive();
		
		//TR corner:
		if (TR_CORNERSIZE > 0.1) {
			addvertexflowui(centerx, centery, distfromside); //center vertex:
			addvertexflowui(RIGHT, TOP - TR_CORNERSIZE, 0.0);
			addvertexflowui(RIGHT - TR_CORNERSIZE, TOP, 0.0);
			EndPrimitive();
		}
	}

	//RIGHT side:
	if (invprogress<0.375) {
		progress_offset = (TOP-BOTTOM - TR_CORNERSIZE - BR_CORNERSIZE) * clamp((invprogress - 0.125) * 4, 0, 1.0);
		
		addvertexflowui(centerx, centery, distfromside); //center vertex:
		addvertexflowui(RIGHT, BOTTOM + BR_CORNERSIZE, 0.0);
		addvertexflowui(RIGHT, TOP - TR_CORNERSIZE - progress_offset, 0.0);
		EndPrimitive();
		
		//BR corner:		
		
		if (BR_CORNERSIZE > 0.1) {
			addvertexflowui(centerx, centery, distfromside); //center vertex:
			addvertexflowui(RIGHT - BR_CORNERSIZE, BOTTOM, 0.0);
			addvertexflowui(RIGHT, BOTTOM + BR_CORNERSIZE, 0.0);
			EndPrimitive();
		}
	}
	
	//BOTTOM side:
	if (invprogress<0.625) {
		progress_offset = (RIGHT-LEFT - BL_CORNERSIZE - BR_CORNERSIZE) * clamp((invprogress - 0.375) * 4, 0, 1.0);
		
		addvertexflowui(centerx, centery, distfromside); //center vertex:
		addvertexflowui(LEFT + BL_CORNERSIZE, BOTTOM, 0.0);
		addvertexflowui(RIGHT - BR_CORNERSIZE - progress_offset, BOTTOM, 0.0);
		EndPrimitive();

		//BL corner:
		if (BL_CORNERSIZE > 0.01) {
			addvertexflowui(centerx, centery, distfromside); //center vertex:
			addvertexflowui(LEFT , BOTTOM + BL_CORNERSIZE, 0.0);
			addvertexflowui(LEFT + BL_CORNERSIZE, BOTTOM, 0.0);
			EndPrimitive();
		}
	}
	
	//LEFT side:
	if (invprogress<0.875) {
		progress_offset = (TOP-BOTTOM - BL_CORNERSIZE - TL_CORNERSIZE) * clamp((invprogress - 0.625) * 4, 0, 1.0);
		
		addvertexflowui(centerx, centery, distfromside); //center vertex:
		addvertexflowui(LEFT, TOP - TL_CORNERSIZE, 0.0);
		addvertexflowui(LEFT, BOTTOM + BL_CORNERSIZE + progress_offset, 0.0);
		EndPrimitive();
		
		//TL corner:
		if (TL_CORNERSIZE > 0.01) {
			addvertexflowui(centerx, centery, distfromside); //center vertex:
			addvertexflowui(LEFT + TL_CORNERSIZE, TOP, 0.0);
			addvertexflowui(LEFT, TOP - TL_CORNERSIZE, 0.0);
			EndPrimitive();
		}
	}
	
	//TOPLEFT side:
	progress_offset = (RIGHT-LEFT - TL_CORNERSIZE) * clamp((invprogress - 0.875) * 4, 0, 1.0);
	addvertexflowui(centerx, centery, distfromside); //center vertex:
	addvertexflowui(centerx, TOP, 0.0);
	addvertexflowui(LEFT + TL_CORNERSIZE + progress_offset, TOP, 0.0);
	EndPrimitive();
	
	
	//for (float i = 0; i<4; i = i+1){ // LOL ROUNDING?!
	//	float a1 = HALFPI * i /4.0;
	//	float a2 = HALFPI * (i+1) /4.0;
	//	addvertexflowui((LEFT + RIGHT) * 0.5, (TOP + BOTTOM) * 0.5);//center vertex:
	//	addvertexflowui(LEFT + (1.0-sin(a1)) * BL_CORNERSIZE, BOTTOM + (1.0-cos(a1)) * BL_CORNERSIZE);
	//	addvertexflowui(LEFT + (1.0-sin(a2)) * BL_CORNERSIZE, BOTTOM + (1.0-cos(a2)) * BL_CORNERSIZE);
	//	EndPrimitive();
	//}
}

]]

local fsSrc = [[
#version 330

#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shading_language_420pack: require


uniform sampler2D bgTex;
uniform sampler2D uiAtlas;

#define BACKGROUND_TILESIZE 64

in DataGS {
	vec4 g_screenpos;
	vec4 g_uv; // should also contain 'background texture shit'
	vec4 g_color;
	vec4 g_color2;
	vec4 g_fronttex_edge_backtex_hide; //v_fronttexture_edge_z_progress
};

out vec4 fragColor;



#line 20000
void main() {
	//vec4 bgTex = texture(bgTex, g_uv.zw/BACKGROUND_TILESIZE); // sample background texture, even if we might discard it
	vec4 fronttex = texture(uiAtlas, g_uv.xy);
	fragColor = g_color;
	//fragColor.rgb = mix(fragColor.rgb, bgTex.rgb, bgTex.a * g_fronttex_edge_backtex_hide.y);
	fragColor.rgba = mix(fragColor.rgba, fronttex.rgba, g_fronttex_edge_backtex_hide.x);// * g_fronttex_edge_backtex_hide.x );
	fragColor.a = max(fragColor.a, g_fronttex_edge_backtex_hide.x*fronttex.a);

	if (g_fronttex_edge_backtex_hide.y <= 99.0) {
		fragColor = g_color2;
		//fragColor.rgba = mix(fragColor.rgba, g_color2, clamp((g_fronttex_edge_backtex_hide.y),0.0, 1.0));
		fragColor.a = min(fragColor.a,clamp(( sign(g_fronttex_edge_backtex_hide.y)),0.0, 1.0));
	}
	//fragColor.rgb  = vec3(clamp((1.0 - g_fronttex_edge_backtex_hide.y),0.0, 1.0), fract(g_fronttex_edge_backtex_hide.y), 0.0);
	//fragColor.a = 1.0;
	//fragColor.a = min(fragColor.a,0.5);
	//fragColor.rgba = vec4(1.0,1.0,1.0,0.3);
	
	// Do the mousepos based highlighting?
	fragColor.rgb += fragColor.rgb * g_fronttex_edge_backtex_hide.z;
	
	
}
]]

local function goodbye(reason)
  Spring.Echo(widget:GetInfo().name .." widget exiting with reason: "..reason)
  widgetHandler:RemoveWidget(self)
end

local function makeRectRoundVBO()
	rectRoundVBO = makeInstanceVBOTable(
		{
			{id = 0, name = 'screenpos', size = 4},
			{id = 1, name = 'cornersizes', size = 4},
			{id = 2, name = 'color1', size = 4},
			{id = 3, name = 'color2', size = 4},
			{id = 4, name = 'uvoffsets', size = 4},
			{id = 5, name = 'fronttexture_edge_z_progress', size = 4},
			{id = 6, name = 'hide_blendmode_globalbackground', size = 4}, -- TODO: maybe Hide, BlendMode, globalbackground
			
		},
		32000	,
		"rectRoundVBO"
	)
	if rectRoundVBO == nil then goodbye("Failed to create rectRoundVBO") end
	
	for i = 1, 0 do
		local l = math.floor(math.random() * vsx/2)
		local b = math.floor(math.random() * vsy/2)
		local r = math.floor(l + math.random() * vsx/4)
		local t = math.floor(b + math.random() * vsx/4)
		local VBOData = {
			l,b,r,t, 
			math.random() * 10, math.random() *20, math.random() * 30, math.random() * 40, 
			math.random() , math.random(), math.random() , math.random() , 
			math.random() , math.random(), math.random() , math.random() , 
			0,0,1,1, --math.random() , math.random(), math.random() , math.random() , 
			math.random() , math.random(), math.random() , math.random() , 
			0,0,0,0,
		}
		
		pushElementInstance(rectRoundVBO,VBOData,i,true)
	end
	return rectRoundVBO
end

local function makeShaders()
	local engineUniformBufferDefs = LuaShader.GetEngineUniformBufferDefs()
	vsSrc = vsSrc:gsub("//__ENGINEUNIFORMBUFFERDEFS__", engineUniformBufferDefs)
	gsSrc = gsSrc:gsub("//__ENGINEUNIFORMBUFFERDEFS__", engineUniformBufferDefs)
	fsSrc = fsSrc:gsub("//__ENGINEUNIFORMBUFFERDEFS__", engineUniformBufferDefs)
	rectRoundShader =  LuaShader(
		{
			vertex = vsSrc,
			fragment = fsSrc,
			geometry = gsSrc,
		
			uniformInt = {
				bgTex = 0,
				uiAtlas = 1,
			},
			uniformFloat = {
				--shaderParams = {gridSize, brightness, (curvature and 1.0) or 0.0, (fogEffect and 1.0) or 0.0},
			},
		},
		"rectRoundShader GL4"
	)
	--Spring.Echo("GS ############################################################ \n",gsSrc)
	shaderCompiled = rectRoundShader:Initialize()
	if not shaderCompiled then
		goodbye("Failed to compile rectRoundShader GL4 ")
		
		--Spring.Echo("VS ############################################################ \n",vsSrc)
		--Spring.Echo("GS ############################################################ \n",gsSrc)
		--Spring.Echo("FS ############################################################ \n",fsSrc)
	else
		Spring.Echo("Compile OK"	)
	end
	
end


---------------------- FlowUI emulation ------------------------
-- Notes
-- the shader should be shared, but each widget should have its own:
--	VBO
--	Atlas

-- TODO:
--	TexturedRectRound:
		--texture UV calcs are wierd
--	RectRoundCircle
	--	Radius in one vertex param! (doable with tris)
	--	 implement centerOffset! 
	-- DOESNT WORK?
	-- COMPLETELY FUCKED!
--	UiElement
	-- repurpose blendalpha to bgtexture, and have that global
--	Draw.TexRect
	-- implement the UV offsets from atlastexture
-- Configints
	-- somehow mash them into this table?

	--[[			{id = 0, name = 'screenpos', size = 4},
			{id = 1, name = 'cornersizes', size = 4},
			{id = 2, name = 'color1', size = 4},
			{id = 3, name = 'color2', size = 4},
			{id = 4, name = 'uvoffsets', size = 4},
			{id = 5, name = 'fronttexture_edge_z_progress', size = 4},]]--



Draw.TransformUVAtlasxXyY = function (atlascoordsxXyY, uvcoordsxyXY)
	if atlascoordsxXyY == nil or uvcoordsxyXY == nil then 
		return {0,0,1,1}
	end
	local a = atlascoordsxXyY[2] - atlascoordsxXyY[1]
	local b = atlascoordsxXyY[4] - atlascoordsxXyY[3]
	return {
		atlascoordsxXyY[1] + a * uvcoordsxyXY[1],
		atlascoordsxXyY[3] + b * uvcoordsxyXY[2],
		atlascoordsxXyY[1] + a * uvcoordsxyXY[3],
		atlascoordsxXyY[3] + b * uvcoordsxyXY[4],
		}
end


--[[
	RectRound
		draw rectangle with chopped off corners
	params
		px, py, sx, sy = left, bottom, right, top
	optional
		cs = corner size
		tl, tr, br, bl = enable/disable corners for TopLeft, TopRight, BottomRight, BottomLeft (default: 1)
		c1, c2 = top color, bottom color
]]--
Draw.RectRound = function (VBO, instanceID, z, px, py, sx, sy,  cs,  tl, tr, br, bl,   c1, c2, progress) -- returns table of instanceIDs

	if z == nil then z = 0.5 end  -- fools depth sort
	if c1 == nil then c1 = {1.0,1.0,1.0,1.0} end
	if c2 == nil then c2 = c1 end
	progress = progress or 1
	--Spring.Echo(c1)
	--Spring.Echo(c2)
	
	--cs = 10
	local VBOData = {
		px, py, sx, sy, 
		cs*tl, cs*tr, cs*br, cs*bl, 
		c1[1], c1[2], c1[3], c1[4],
		c2[1], c2[2], c2[3], c2[4],
		0,0,0,0,
		0, 0, z, 1,
		0,0,0,0,
		}
	return pushElementInstance(VBO, VBOData, instanceID,true)
end

-- this is just an overload for replacing gl.TexRect
Draw.TexRect = function (VBO, instanceID, z, px, py, sx, sy,  texture, color, uvs) -- returns table of instanceIDs
	
	return Draw.TexturedRectRound(VBO, instanceID, z, px, py, sx, sy,  0,  0, 0, 0, 0,  0, 0, 0,  texture)
	--[[
	if z == nil then z = 0.5 end  -- fools depth sort
	
	local fronttextalpha = 0
	if texture == nil then 
		texture = {0,0,0,0}
	else
		fronttextalpha = 1.0
		Spring.Echo('TexRect',texture)
		texture = ({gl.GetAtlasTexture(atlasID, texture)})
		Spring.Echo(texture)
	end 
	if uvs == nil then uvs = {0,0,1,1} end
	-- remap uvs
	
	uvs = Draw.TransformUVAtlasxXyY(texture, uvs)
	
	if color == nil then color = {1,1,1,1} end
	local VBOData = {
		px, py, sx, sy, 
		0, 0, 0, 0, 
		color[1],color[2],color[3],color[4],
		color[1],color[2],color[3],color[4],
		uvs[1],uvs[4],uvs[3],uvs[2],
		fronttextalpha, 0, z, 1,
		0,0,0,0,
		}
	return pushElementInstance(VBO, VBOData, instanceID,true)
	]]--	
end
--[[
	TexturedRectRound
		draw rectangle with chopped off corners and a textured background tile
	params
		px, py, sx, sy = left, bottom, right, top
	optional
		tl, tr, br, bl = enable/disable corners for TopLeft, TopRight, BottomRight, BottomLeft (default: 1)
		size = texture tile size
		offset, offsetY = texture offset coordinates (offsetY=offset when offsetY isnt defined)
		texture = file location
]]--

Draw.TexturedRectRound =  function (VBO, instanceID, z, px, py, sx, sy,  cs,  tl, tr, br, bl,  size, offset, offsetY,  texture, color) -- returns table of instanceIDs
	-- texture should be a table of UV coords from atlas
	local fronttextalpha = 0
	if texture == nil then 
		texture = {0,0,0,0}
	else
		fronttextalpha = 1.0
		--Spring.Echo('TexturedRectRound',texture)
		if atlasID == nil or texture == nil then 
			--Spring.Debug.TraceFullEcho(30,30,30)
			Spring.Echo(atlasID, texture)
		end
		texture = ({gl.GetAtlasTexture(atlasID, texture)})
		--Spring.Echo(texture)
	end 
	
	if color == nil then color = {1,1,1,0.5} end
	--uvs = Draw.TransformUVAtlasxXyY(texture, uvs) -- DO OFFSET!
	local scale = size and (size / (sx-px)) or 1
	--local offset = offset or 0
	local csyMult = 1 / ((sy - py) / cs)
	local ycMult = (sy-py) / (sx-px)
	
	if z == nil then z = 0.50 end  -- fools depth sort
	if c2 == nil then c2 = c1 end
	local VBOData = {
		px, py, sx, sy, 
		cs*tl, cs*tr, cs*br, cs*bl, 
		color[1],color[2],color[3],color[4],
		color[1],color[2],color[3],color[4],
		texture[1],texture[4],texture[2],texture[3],
		fronttextalpha, 0, z, 1,
		0,0,0,0,
		}
	return pushElementInstance(VBO, VBOData, instanceID,true)
end


--[[
	RectRoundProgress
		draw rectangle pie (TODO: not with actual chopped off corners yet)
	params
		px, py, sx, sy = left, bottom, right, top
	optional
		cs = corner size
		progress
		color
]]
Draw.RectRoundProgress =  function (VBO, instanceID, z, left, bottom, right, top, cs, progress, c1, c2) -- returns table of instanceIDs
	return Draw.RectRound(VBO, instanceID, z, left, bottom, right, top, cs, 1,1,1,1, c1, c2, progress)
	--[[
	if z == nil then z = 0.55 end  -- fools depth sort
	if c2 == nil then c2 = c1 end
	local VBOData = {
		left, bottom, right, top, 
		cs*tl, cs*tr, cs*br, cs*bl, 
		c1[1], c1[2], c1[3], c1[4],
		c1[1], c1[2], c1[3], c1[4],
		0,0,0,0,
		0, 0, z, progress,
		0,0,0,0,
		}
	return pushElementInstance(VBO, VBOData, instanceID,true)]]--
end



--[[
	RectRoundCircle
		draw a square with border edge/fade
	params
		x,y,z, radius
	optional
		c1 : outercolor
		c2 : innercolor
		centeroffset: the width of the highlight is gonna be radius-centeroffset

]]
Draw.RectRoundCircle = function (VBO, instanceID, z, x, y, radius, cs, centerOffset, c1, c2) -- returns table of instanceIDs
	Spring.Echo("Draw.RectRoundCircle", x, y, radius, cs, centerOffset, c1, c2)
	Spring.Echo(radius, radius - centerOffset)
	if z == nil then z = 0.5 end  -- fools depth sort
	if c1 == nil then c1 = {1.0,1.0,1.0,1.0} end
	if c2 == nil then c2 = c1 end
	if centerOffset == nil then centerOffset = 0 end
	--centerOffset = 50
	
	--local cs = radius / 2
	
	local VBOData = {
		x - radius, y - radius, x + radius, y + radius, 
		cs, cs, cs, cs, 
		c1[1], c1[2], c1[3], c1[4],
		c2[1], c2[2], c2[3], c2[4],
		0,0,0,0,
		0, radius - centerOffset , z, 1,
		0,0,0,0,
		}
	return pushElementInstance(VBO, VBOData, instanceID,true)
end

--[[
	Circle
		draw a circle
	params
		x,z, radius
		sides = number outside vertexes
		color1 = (center) color
	optional
		color2 = edge color
]]-- -- TODO


--[[
	UiElement
		draw a complete standardized ui element having: border, tiled background, gloss on top and bottom
	params
		px, py, sx, sy = left, bottom, right, top
	optional
		tl, tr, br, bl = enable/disable corners for TopLeft, TopRight, BottomRight, BottomLeft (default: 1)
		ptl, ptr, pbr, pbl = inner border padding/size multiplier (default: 1) (set to 0 when you want to attach this ui element to another element so there is only padding done by one of the 2 elements)
		opacity = (default: ui_opacity springsetting)
		color1, color2 = (color1[4 value overrides the opacity param defined above)
		bgpadding = custom border size
]]

Draw.Element = function(VBO, instanceID, z,px, py, sx, sy,  tl, tr, br, bl,  ptl, ptr, pbr, pbl,  opacity, color1, color2, bgpadding)
	local opacity = opacity or Spring.GetConfigFloat("ui_opacity", 0.6)
	local color1 = color1 or { 0, 0, 0, opacity}
	local color2 = color2 or { 1, 1, 1, opacity * 0.1}
	local ui_scale = Spring.GetConfigFloat("ui_scale", 1)
	local bgpadding = bgpadding or WG.FlowUI.elementPadding
	local cs = WG.FlowUI.elementCorner * (bgpadding/WG.FlowUI.elementPadding)
	local glossMult = 1 + (2 - (opacity * 1.5))
	local tileopacity = Spring.GetConfigFloat("ui_tileopacity", 0.012)
	local bgtexScale = Spring.GetConfigFloat("ui_tilescale", 7)
	local bgtexSize = math.floor(WG.FlowUI.elementPadding * bgtexScale)

	local tl = tl or 1
	local tr = tr or 1
	local br = br or 1
	local bl = bl or 1

	local pxPad = bgpadding * (px > 0 and 1 or 0) * (pbl or 1)
	local pyPad = bgpadding * (py > 0 and 1 or 0) * (pbr or 1)
	local sxPad = bgpadding * (sx < WG.FlowUI.vsx and 1 or 0) * (ptr or 1)
	local syPad = bgpadding * (sy < WG.FlowUI.vsy and 1 or 0) * (ptl or 1)
	
	if z == nil then z = 0.5 end  -- fools depth sort
	
	-- background
	--gl.Texture(false)
	local background1 = Draw.RectRound(VBO, nil, z-0.000, px, py, sx, sy, cs, tl, tr, br, bl, { color1[1], color1[2], color1[3], color1[4] }, { color1[1], color1[2], color1[3], color1[4] })

	cs = cs * 0.6
	local background2 = Draw.RectRound(VBO, nil, z-0.001,px + pxPad, py + pyPad, sx - sxPad, sy - syPad, cs, tl, tr, br, bl, { color2[1]*0.33, color2[2]*0.33, color2[3]*0.33, color2[4] }, { color2[1], color2[2], color2[3], color2[4] })

	-- gloss
	--gl.Blending(GL.SRC_ALPHA, GL.ONE)
	local glossHeight = math.floor(0.02 * WG.FlowUI.vsy * ui_scale)
	-- top
	local topgloss = Draw.RectRound(VBO, nil, z-0.002,px + pxPad, sy - syPad - glossHeight, sx - sxPad, sy - syPad, cs, tl, tr, 0, 0, { 1, 1, 1, 0 }, { 1, 1, 1, 0.07 * glossMult })
	-- bottom
	local botgloss = Draw.RectRound(VBO, nil, z-0.003,px + pxPad, py + pyPad, sx - sxPad, py + pyPad + glossHeight, cs, 0, 0, br, bl, { 1, 1, 1, 0.03 * glossMult }, { 1 ,1 ,1 , 0 })

	-- highlight edges thinly
	-- top
	local topgloss = Draw.RectRound(VBO, nil, z-0.004,px + pxPad, sy - syPad - (cs*2.5), sx - sxPad, sy - syPad, cs, tl, tr, 0, 0, { 1, 1, 1, 0 }, { 1, 1, 1, 0.04 * glossMult })
	-- bottom
	local botgloss = Draw.RectRound(VBO, nil, z-0.005,px + pxPad, py + pyPad, sx - sxPad, py + pyPad + (cs*2), cs, 0, 0, br, bl, { 1, 1, 1, 0.02 * glossMult }, { 1 ,1 ,1 , 0 })
	-- left
	--WG.FlowUI.Draw.RectRound(px + pxPad, py + syPad, px + pxPad + (cs*2), sy - syPad, cs, tl, tr, 0, 0, { 1, 1, 1, 0.02 * glossMult }, { 1, 1, 1, 0 })
	-- right
	--WG.FlowUI.Draw.RectRound(sx - sxPad - (cs*2), py + syPad, sx - sxPad, sy - syPad, cs, tl, tr, 0, 0, { 1, 1, 1, 0.02 * glossMult }, { 1, 1, 1, 0 })

	--WG.FlowUI.Draw.RectRound(px + (pxPad*1.6), sy - syPad - math.ceil(bgpadding*0.25), sx - (sxPad*1.6), sy - syPad, 0, tl, tr, 0, 0, { 1, 1, 1, 0.012 }, { 1, 1, 1, 0.07 * glossMult })
	--gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)

	-- darkening bottom
	local botdark = Draw.RectRound(VBO, nil, z-0.006,px, py, sx, py + ((sy-py)*0.75), cs*1.66, 0, 0, br, bl, { 0,0,0, 0.05 * glossMult }, { 0,0,0, 0 })
	local instanceIDs = {background1, background2, topgloss, botgloss, botdark}
	-- tile
	if tileopacity > 0 then
		--gl.Color(1,1,1, tileopacity)
		local bgtile = Draw.TexturedRectRound(VBO, nil, z-0.007,px + pxPad, py + pyPad, sx - sxPad, sy - syPad, cs, tl, tr, br, bl, bgtexSize, (px+pxPad)/WG.FlowUI.vsx/bgtexSize, (py+pyPad)/WG.FlowUI.vsy/bgtexSize, "luaui/images/flowui_gl4/backgroundtile.png")
		instanceIDs[#instanceIDs + 1 ] = bgtile
	end
	return instanceIDs
end


--[[
	Button
		draw a complete standardized ui element having: border, tiled background, gloss on top and bottom
	params
		px, py, sx, sy = left, bottom, right, top
	optional
		tl, tr, br, bl = enable/disable corners for TopLeft, TopRight, BottomRight, BottomLeft (default: 1)
		ptl, ptr, pbr, pbl = inner padding multiplier (default: 1) (set to 0 when you want to attach this ui element to another element so there is only padding done by one of the 2 elements)
		opacity = (default: ui_opacity springsetting)
		color1, color2 = (color1[4] alpha value overrides opacity define above)
		bgpadding = custom border size
]]
Draw.Button = function(VBO, instanceID, z,px, py, sx, sy,  tl, tr, br, bl,  ptl, ptr, pbr, pbl,  opacity, color1, color2, bgpadding)
	local opacity = opacity or 1
	local color1 = color1 or { 0, 0, 0, opacity}
	local color2 = color2 or { 1, 1, 1, opacity * 0.1}
	local bgpadding = math.floor(bgpadding or WG.FlowUI.buttonPadding*0.5)
	local glossMult = 1 + (2 - (opacity * 1.5))

	local tl = tl or 1
	local tr = tr or 1
	local br = br or 1
	local bl = bl or 1

	local pxPad = bgpadding * (px > 0 and 1 or 0) * (pbl or 1)
	local pyPad = bgpadding * (py > 0 and 1 or 0) * (pbr or 1)
	local sxPad = bgpadding * (sx < WG.FlowUI.vsx and 1 or 0) * (ptr or 1)
	local syPad = bgpadding * (sy < WG.FlowUI.vsy and 1 or 0) * (ptl or 1)
	
	if z == nil then z = 0.5 end  -- fools depth sort
	glossMult = glossMult * 1 -- TODO TESTING REMOVE!
	
	-- background
	--gl.Texture(false)
	local background = Draw.RectRound(VBO, nil, z-0.000,px, py, sx, sy, bgpadding * 1.6, tl, tr, br, bl, { color1[1], color1[2], color1[3], color1[4] }, { color2[1], color2[2], color2[3], color2[4] })
	--WG.FlowUI.Draw.RectRound(px + pxPad, py + pyPad, sx - sxPad, sy - syPad, bgpadding, tl, tr, br, bl, { color2[1]*0.33, color2[2]*0.33, color2[3]*0.33, color2[4] }, { color2[1], color2[2], color2[3], color2[4] })

	-- highlight edges thinly
	-- top
	local highlighttop = Draw.RectRound(VBO, nil, z-0.001,px + pxPad, sy - syPad - (bgpadding*2.5), sx - sxPad, sy - syPad, bgpadding, tl, tr, 0, 0, { 1, 1, 1, 0 }, { 1, 1, 1, 0.04 * glossMult })
	-- bottom
	local highlightbottom = Draw.RectRound(VBO, nil, z-0.001,px + pxPad, py + pyPad, sx - sxPad, py + pyPad + (bgpadding*2), bgpadding, 0, 0, br, bl, { 1, 1, 1, 0.02 * glossMult }, { 0 ,0 ,0 , 0 })

	-- gloss
	--gl.Blending(GL.SRC_ALPHA, GL.ONE)
	local glossHeight = math.floor((sy-py)*0.5)
	local gloss1 = Draw.RectRound(VBO, nil, z-0.002,px + pxPad, sy - syPad - math.floor((sy-py)*0.5), sx - sxPad, sy - syPad, bgpadding, tl, tr, 0, 0, { 1, 1, 1, 0.03 }, { 1, 1, 1, 0.1 * glossMult })
	local gloss2 = Draw.RectRound(VBO, nil, z-0.002,px + pxPad, py + pyPad, sx - sxPad, py + pyPad + glossHeight, bgpadding, 0, 0, br, bl, { 1, 1, 1, 0.03 * glossMult }, { 1 ,1 ,1 , 0 })
	local gloss3 = Draw.RectRound(VBO, nil, z-0.002,px + pxPad, py + pyPad, sx - sxPad, py + pyPad + ((sy-py)*0.2), bgpadding, 0, 0, br, bl, { 1,1,1, 0.02 * glossMult }, { 1,1,1, 0 })
	local gloss4 = Draw.RectRound(VBO, nil, z-0.002,px + pxPad, sy- ((sy-py)*0.5), sx - sxPad, sy, bgpadding, tl, tr, 0, 0, { 1,1,1, 0 }, { 1,1,1, 0.07 * glossMult })
	local gloss5 = Draw.RectRound(VBO, nil, z-0.002,px + pxPad, py + pyPad, sx - sxPad, py + pyPad + ((sy-py)*0.5), bgpadding, 0, 0, br, bl, { 1,1,1, 0.05 * glossMult }, { 1,1,1, 0 })
	--gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
	return {background,highlighttop,highlightbottom, gloss1, gloss2, gloss3, gloss4, gloss5}
end

--[[
	Unit
		draw a unit buildpic
	params
		px, py, sx, sy = left, bottom, right, top
	optional
		cs = corner size
		tl, tr, br, bl = enable/disable corners for TopLeft, TopRight, BottomRight, BottomLeft (default: 1)
		zoom = how much to enlarge/zoom into the buildpic (default:  0)
		borderSize, borderOpacity,
		texture, radarTexture, groupTexture,
		price = {metal, energy}
		queueCount
]]
Draw.Unit = function(VBO, instanceID, z, px, py, sx, sy,  cs,  tl, tr, br, bl,  zoom,  borderSize, borderOpacity,  texture, radarTexture, groupTexture, price, queueCount)
	local borderSize = borderSize~=nil and borderSize or math.min(math.max(1, math.floor((sx-px) * 0.024)), math.floor((WG.FlowUI.vsy*0.0015)+0.5))	-- set default with upper limit
	local cs = cs~=nil and cs or math.max(1, math.floor((sx-px) * 0.024))

	-- draw unit
	--[[
	if texture then
		gl.Texture(texture)
	end
	gl.BeginEnd(GL.QUADS, DrawTexRectRound, px, py, sx, sy,  cs,  tl, tr, br, bl,  zoom)
	if texture then
		gl.Texture(false)
	end]]--
	
	if texture then
		--texture = gl.GetAtlasTexture(atlasID, texture)
	else
		--texture = {0,0,0,0}
	end
	
	local unitpic = Draw.TexturedRectRound(VBO, nil, z + 0.001,
		px, py, sx, sy,  cs,  tl, tr, br, bl,  zoom, nil,nil, 
		texture
	)
	

	-- darken gradually
	local darken = Draw.RectRound(VBO, nil, z + 0.002, px, py, sx, sy, cs, 0, 0, 1, 1, { 0, 0, 0, 0.2 }, { 0, 0, 0, 0 })

	-- make shiny
	--gl.Blending(GL.SRC_ALPHA, GL.ONE)
	
	local shiny = Draw.RectRound(VBO, nil, z + 0.003, px, sy-((sy-py)*0.4), sx, sy, cs, 1,1,0,0,{1,1,1,0}, {1,1,1,0.06})

	-- lighten feather edges
	borderOpacity = borderOpacity or 0.1
	local halfSize = ((sx-px) * 0.5)
	
	local lighten = Draw.RectRoundCircle(VBO, nil, z + 0.004,
		px + halfSize,
		py + halfSize,
		halfSize, cs*0.7, halfSize*0.82,
		--{ 1, 1, 1, 0 }, { 1, 1, 1, 0.04 } -- original
		{ 1, 1, 1, 0 }, { 1, 1, 1, 0.24 } -- original
		--{ 1, 0, 1, 1.0 }, { 0, 1, 0, 1.0 }
	)

	local elementIDs = {unitpic, darken, shiny, lighten}
	
	-- border
	
	if borderSize > 0 then
		elementIDs[#elementIDs+1] = Draw.RectRoundCircle(
			VBO, nil, z + 0.005,
			px + halfSize,
			py + halfSize,
			halfSize, cs*0.7, halfSize -  borderSize,
			{ 1, 1, 1, borderOpacity }, { 1, 1, 1, borderOpacity }
		)
	end	
	--gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)

	if groupTexture then
		local iconSize = math.floor((sx - px) * 0.3)
		--gl.Color(1, 1, 1, 0.9)
		--gl.Texture(groupTexture)
		--gl.TexRect(px, sy - iconSize, px + iconSize, sy)
		--gl.Texture(false)
		
		elementIDs[#elementIDs+1] = Draw.TexRect(VBO, nil, z + 0.006,
			px, sy - iconSize, px + iconSize, sy,
			groupTexture,
			{1, 1, 1, 0.9})
			
	end
	if radarTexture then
		local iconSize = math.floor((sx - px) * 0.25)
		local iconPadding = math.floor((sx - px) * 0.03)
		--gl.Color(1, 1, 1, 0.9)
		--gl.Texture(radarTexture)
		--gl.TexRect(sx - iconPadding - iconSize, py + iconPadding, sx - iconPadding, py + iconPadding + iconSize)
		--gl.Texture(false)
		
		elementIDs[#elementIDs+1] = Draw.TexRect(VBO, nil, z + 0.006,
			sx - iconPadding - iconSize, py + iconPadding, sx - iconPadding, py + iconPadding + iconSize,
			radarTexture,
			{1, 1, 1, 0.9})
	end
	if price then
		local priceSize = math.floor((sx - px) * 0.15)
		local iconPadding = math.floor((sx - px) * 0.03)
		--font2:Print("\255\245\245\245" .. price[1] .. "\n\255\255\255\000" .. price[2], px + iconPadding, py + iconPadding + (priceSize * 1.35), priceSize, "o")
	end
	if queueCount then
		local pad = math.floor(halfSize * 0.06)
		--local textWidth = math.floor(font2:GetTextWidth(cmds[cellRectID].params[1] .. '  ') * halfSize * 0.57)
		--local pad2 = 0
		--WG.FlowUI.Draw.RectRound(cellRects[cellRectID][3] - cellPadding - iconPadding - textWidth - pad2, cellRects[cellRectID][4] - cellPadding - iconPadding - (cellInnerSize * 0.365) - pad2, cellRects[cellRectID][3] - cellPadding - iconPadding, cellRects[cellRectID][4] - cellPadding - iconPadding, cs * 3.3, 0, 0, 0, 1, { 0.15, 0.15, 0.15, 0.95 }, { 0.25, 0.25, 0.25, 0.95 })
		--WG.FlowUI.Draw.RectRound(cellRects[cellRectID][3] - cellPadding - iconPadding - textWidth - pad2, cellRects[cellRectID][4] - cellPadding - iconPadding - (cellInnerSize * 0.15) - pad2, cellRects[cellRectID][3] - cellPadding - iconPadding, cellRects[cellRectID][4] - cellPadding - iconPadding, 0, 0, 0, 0, 0, { 1, 1, 1, 0 }, { 1, 1, 1, 0.05 })
		--WG.FlowUI.Draw.RectRound(cellRects[cellRectID][3] - cellPadding - iconPadding - textWidth - pad2 + pad, cellRects[cellRectID][4] - cellPadding - iconPadding - (cellInnerSize * 0.365) - pad2 + pad, cellRects[cellRectID][3] - cellPadding - iconPadding - pad2, cellRects[cellRectID][4] - cellPadding - iconPadding - pad2, cs * 2.6, 0, 0, 0, 1, { 0.7, 0.7, 0.7, 0.1 }, { 1, 1, 1, 0.1 })
		--font2:Print("\255\190\255\190" .. cmds[cellRectID].params[1],
		--	cellRects[cellRectID][1] + cellPadding + (halfSize * 1.88) - pad2,
		--	cellRects[cellRectID][2] + cellPadding + (halfSize * 1.43) - pad2,
		--	(sx - px) * 0.29, "ro"
		--)
	end
	return elementIDs
end

--[[
	Scroller
		draw a slider
	params
		px, py, sx, sy = left, bottom, right, top
		contentHeight = content height px
	optional
		position = (default: 0) current height px
]]
Draw.Scroller = function(VBO, instanceID, z, px, py, sx, sy, contentHeight, position)
	if z == nil then z = 0.5 end
	local padding = math.floor(((sx-px)*0.25) + 0.5)
	local sliderHeight =  (sy - py - padding - padding) / contentHeight
	--if sliderHeight < 1 then
	position = position or 0
	sliderHeight = math.floor((sliderHeight * (sy - py)) + 0.5)
	local sliderPos = math.floor((sy - ((sy - py) * (position / contentHeight))) + 0.5)

	-- background
	local background = Draw.RectRound(VBO, nil, z, px, py, sx, sy, (sx-px)*0.2, 1,1,1,1, { 0,0,0,0.2 })

	-- slider
	local slider = Draw.RectRound(VBO, nil, z -0.001, px+padding, sliderPos-sliderHeight-padding, sx-padding, sliderPos-padding, (sx-px-padding-padding)*0.2, 1,1,1,1, { 1, 1, 1, 0.16 })
	
	return {background, slider}
	--end
end

--[[
	Toggle
		draw a toggle
	params
		px, py, sx, sy = left, bottom, right, top
	optional
		state = (default: 0) 0 / 0.5 / 1
]]
Draw.Toggle = function(VBO, instanceID, z, px, py, sx, sy, state)
	local cs = (sy-py)*0.1
	local edgeWidth = math.max(1, math.floor((sy-py) * 0.1))

	-- faint dark outline edge
	local outlineedge = Draw.RectRound(VBO, nil, z - 0.000, px-edgeWidth, py-edgeWidth, sx+edgeWidth, sy+edgeWidth, cs*1.5, 1,1,1,1, { 0,0,0,0.05 })
	-- top
	local top = Draw.RectRound(VBO, nil, z - 0.001, px, py, sx, sy, cs, 1,1,1,1, { 0.5, 0.5, 0.5, 0.12 }, { 1, 1, 1, 0.12 })

	-- highlight
	--gl.Blending(GL.SRC_ALPHA, GL.ONE)
	-- top
	local highlighttop = Draw.RectRound(VBO, nil, z - 0.002, px, sy-(edgeWidth*3), sx, sy, edgeWidth, 1,1,1,1, { 1,1,1,0 }, { 1,1,1,0.035 })
	-- bottom
	local highlightbottom = Draw.RectRound(VBO, nil, z - 0.003, px, py, sx, py+(edgeWidth*3), edgeWidth, 1,1,1,1, { 1,1,1,0.025 }, { 1,1,1,0  })
	--gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)

	-- draw state
	local padding = math.floor((sy-py)*0.2)
	local radius = math.floor((sy-py)/2) - padding
	local y = math.floor(py + ((sy-py)/2))
	local x, color, glowMult
	if state == true or state == 1 then		-- on
		x = sx - padding - radius
		color = {0.8,1,0.8,1}
		glowMult = 1
	elseif not state or state == 0 then		-- off
		x = px + padding + radius
		color = {0.95,0.66,0.66,1}
		glowMult = 0.3
	else		-- in between
		x = math.floor(px + ((sx-px)*0.42))
		color = {1,0.9,0.7,1}
		glowMult = 0.6
	end
	local sliderknob  = Draw.SliderKnob(VBO, nil, z - 0.004, x, y, radius, color)

	local instanceIDs = {outlineedge, top, highlighttop, highlightbottom}
	for _, iID in ipairs(sliderknob) do
		instanceIDs[#instanceIDs] = iID
	end
	if glowMult > 0 then
		local boolGlow = radius * 1.75
		--gl.Blending(GL.SRC_ALPHA, GL.ONE)
		--gl.Color(color[1], color[2], color[3], 0.33 * glowMult)
		--gl.Texture(":l:LuaUI/Images/glow.dds")
		--gl.TexRect(x-boolGlow, y-boolGlow, x+boolGlow, y+boolGlow)
		color[4] = 0.33 * glowMult
		local glow1 = Draw.TexRect(VBO, nil, z - 0.005, x-boolGlow, y-boolGlow, x+boolGlow, y+boolGlow,"LuaUI/Images/flowui_gl4/glow.dds", color, nil)
		
		boolGlow = boolGlow * 2.2
		--gl.Color(0.55, 1, 0.55, 0.1 * glowMult)
		--gl.TexRect(x-boolGlow, y-boolGlow, x+boolGlow, y+boolGlow)
		local glow2 = Draw.TexRect(VBO, nil, z - 0.006, x-boolGlow, y-boolGlow, x+boolGlow, y+boolGlow,"LuaUI/Images/flowui_gl4/glow.dds" ,{0.55, 1, 0.55, 0.1 * glowMult},nil)
		--gl.Texture(false)
		--gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
		instanceIDs[#instanceIDs] = glow1
		instanceIDs[#instanceIDs] = glow2
		
	end
	return instanceIDs
end

--[[
	Slider
		draw a slider knob
	params
		x, y, radius
	optional
		color
]]
Draw.SliderKnob = function(VBO, instanceID, z, x, y, radius, color)
	if z == nil then z = 0.5 end
	local color = color or {0.95,0.95,0.95,1}
	local color1 = {color[1]*0.55, color[2]*0.55, color[3]*0.55, color[4]}
	local edgeWidth = math.max(1, math.floor(radius * 0.05))
	local cs = math.max(1.1, radius*0.15)

	-- faint dark outline edge
	local outline = Draw.RectRound(VBO, nil, z - 0.000, x-radius-edgeWidth, y-radius-edgeWidth, x+radius+edgeWidth, y+radius+edgeWidth, cs, 1,1,1,1, {0,0,0,0.1})
	-- knob
	local knob = Draw.RectRound(VBO, nil, z - 0.001,x-radius, y-radius, x+radius, y+radius, cs, 1,1,1,1, color1, color)
	-- lighten knob inside edges
	-- TODO:
	local lighttenknob = Draw.RectRoundCircle(VBO, nil, z - 0.002, x, y, radius, cs*0.5, radius*0.85, {1,1,1,0.1})
	return {outline, knob, lighttenknob}
end


--[[
	Slider
		draw a slider
	params
		px, py, sx, sy = left, bottom, right, top
		steps = either a table of values or a number of smallest step size
		min, max = when steps is number: min/max scope of steps
]]
Draw.Slider = function(VBO, instanceID, z, px, py, sx, sy, steps, min, max)
	if z == nil then z = 0.5 end
	
	local cs = (sy-py)*0.25
	local edgeWidth = math.max(1, math.floor((sy-py) * 0.1))
	-- faint dark outline edge
	local darkoutline = Draw.RectRound(VBO, nil, z - 0.000, px-edgeWidth, py-edgeWidth, sx+edgeWidth, sy+edgeWidth, cs*1.5, 1,1,1,1, { 0,0,0,0.05 })
	-- top
	local top = Draw.RectRound(VBO, nil, z - 0.001, px, py, sx, sy, cs, 1,1,1,1, { 0.1, 0.1, 0.1, 0.22 }, { 0.9,0.9,0.9, 0.22 })
	-- bottom
	local bottom = Draw.RectRound(VBO, nil, z - 0.002, px, py, sx, sy, cs, 1,1,1,1, { 1, 1, 1, 0.1 }, { 1, 1, 1, 0 })
	local instanceIDs = {darkoutline, top, bottom}
	-- steps
	if steps then
		local numSteps = 0
		local sliderWidth = sx-px
		local processedSteps = {}
		if type(steps) == 'table' then
			min = steps[1]
			max = steps[#steps]
			numSteps = #steps
			for _,value in pairs(steps) do
				processedSteps[#processedSteps+1] = math.floor((px + (sliderWidth*((value-min)/(max-min)))) + 0.5)
			end
			-- remove first step at the bar start
			processedSteps[1] = nil
		elseif min and max then
			numSteps = (max-min)/steps
			for i=1, numSteps do
				processedSteps[#processedSteps+1] = math.floor((px + (sliderWidth/numSteps) * (#processedSteps+1)) + 0.5)
				i = i + 1
			end
		end
		-- remove last step at the bar end
		processedSteps[#processedSteps] = nil

		-- dont bother when steps too small
		if numSteps and numSteps < (sliderWidth/7) then
			local stepSizeLeft = math.max(1, math.floor(sliderWidth*0.01))
			local stepSizeRight = math.floor(sliderWidth*0.005)
			for _,posX in pairs(processedSteps) do
				local step = Draw.RectRound(VBO, nil, z - 0.001 * #instanceIDs,posX-stepSizeLeft, py+1, posX+stepSizeRight, sy-1, stepSizeLeft, 1,1,1,1, { 0.12,0.12,0.12,0.22 }, { 0,0,0,0.22 })
				instanceIDs[#instanceIDs] = step
			end
		end
	end

	-- add highlight
	--gl.Blending(GL.SRC_ALPHA, GL.ONE)
	-- top
	local tophighlight = Draw.RectRound(VBO, nil, z - 0.001 * #instanceIDs,px, sy-edgeWidth-edgeWidth, sx, sy, edgeWidth, 1,1,1,1, { 1,1,1,0 }, { 1,1,1,0.06 })
	instanceIDs[#instanceIDs] = tophighlight
	-- bottom
	
	local bottomhighlight = Draw.RectRound(VBO, nil, z - 0.001 * #instanceIDs,px, py, sx, py+edgeWidth+edgeWidth, edgeWidth, 1,1,1,1, { 1,1,1,0 }, { 1,1,1,0.04 })
	instanceIDs[#instanceIDs] = bottomhighlight
	--gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
	return instanceIDs
end

--[[
	Selector
		draw a selector (drop-down menu)
	params
		px, py, sx, sy = left, bottom, right, top
]]
Draw.Selector = function(VBO, instanceID, z, px, py, sx, sy)
	z = z or 0.5
	local cs = (sy-py)*0.1
	local edgeWidth = math.max(1, math.floor((sy-py) * 0.1))

	-- faint dark outline edge
	local darkoutline = Draw.RectRound(VBO, nil, z - 0.00, px-edgeWidth, py-edgeWidth, sx+edgeWidth, sy+edgeWidth, cs*1.5, 1,1,1,1, { 0,0,0,0.05 })
	-- body
	local body = Draw.RectRound(VBO, nil, z - 0.001, px, py, sx, sy, cs, 1,1,1,1, { 0.5, 0.5, 0.5, 0.12 }, { 1, 1, 1, 0.12 })

	-- highlight
	--gl.Blending(GL.SRC_ALPHA, GL.ONE)
	-- top
	local tophighlight = Draw.RectRound(VBO, nil, z - 0.002, px, sy-(edgeWidth*3), sx, sy, edgeWidth, 1,1,1,1, { 1,1,1,0 }, { 1,1,1,0.035 })
	-- bottom
	local bottomhighlight = Draw.RectRound(VBO, nil, z - 0.003, px, py, sx, py+(edgeWidth*3), edgeWidth, 1,1,1,1, { 1,1,1,0.025 }, { 1,1,1,0  })
	gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)

	-- button
	local button = Draw.RectRound(VBO, nil, z - 0.004, sx-(sy-py), py, sx, sy, cs, 1, 1, 1, 1, { 1, 1, 1, 0.06 }, { 1, 1, 1, 0.14 })
	
	return {darkoutline, body, tophighlight, bottomhighlight, button}
	--WG.FlowUI.Draw.Button(sx-(sy-py), py, sx, sy, 1, 1, 1, 1, 1,1,1,1, nil, { 1, 1, 1, 0.1 }, nil, cs)
end

--[[
	SelectHighlight
		draw a highlighted area in a selector (drop-down menu)
		(also usable to highlight some other generic area)
	params
		px, py, sx, sy = left, bottom, right, top
		cs = corner size
		opacity
		color = {1,1,1}
]]
Draw.SelectHighlight = function(VBO, instanceID, z, px, py, sx, sy,  cs, opacity, color)
	z = z or 0.5
	local cs = cs or (sy-py)*0.08
	local edgeWidth = math.max(1, math.floor((WG.FlowUI.vsy*0.001)))
	local opacity = opacity or 0.35
	local color = color or {1,1,1}

	-- faint dark outline edge
	local darkoutline = Draw.RectRound(VBO, nil, z - 0.00, px-edgeWidth, py-edgeWidth, sx+edgeWidth, sy+edgeWidth, cs*1.5, 1,1,1,1, { 0,0,0,0.05 })
	-- body
	local body = Draw.RectRound(VBO, nil, z - 0.001, px, py, sx, sy, cs, 1,1,1,1, { color[1]*0.5, color[2]*0.5, color[3]*0.5, opacity }, { color[1], color[2], color[3], opacity })

	-- highlight
	--gl.Blending(GL.SRC_ALPHA, GL.ONE)
	-- top
	local top = Draw.RectRound(VBO, nil, z - 0.002, px, sy-(edgeWidth*3), sx, sy, edgeWidth, 1,1,1,1, { 1,1,1,0 }, { 1,1,1,0.03 + (0.18*opacity) })
	-- bottom
	local bottom = Draw.RectRound(VBO, nil, z - 0.003, px, py, sx, py+(edgeWidth*3), edgeWidth, 1,1,1,1, { 1,1,1,0.015 + (0.06*opacity) }, { 1,1,1,0  })
	--gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
	return {darkoutline, body, top, bottom}
end

-- remove a set of elements from the VBO
Draw.RemoveUIElements = function(VBO, instanceIDs, noUpload)
	for i,k in ipairs(instanceIDs) do
		popElementInstance(VBO, k, noUpload)
	end
	return noUpload
end

-- toggle the visibilitystate to true, or false, pass nil to toggle the original value 
Draw.ToggleUIElements = function(VBO, instanceIDs, visibilitystate, noUpload)
	local visibility_index = 4 * 6 
	for i,k in ipairs(instanceIDs) do
		local offset = VBO.intanceIDtoIndex[k]
		if k then 
			if visibilitystate ~= nil then
				VBO.instanceData[offset + visibility_index] = visibilitystate
			else
				VBO.instanceData[offset + visibility_index] = 1.0 - VBO.instanceData[offset + visibility_index]
			end
		end
	end
	if noUpload ~= true then 
		uploadAllElements(VBO)
	end
	return noUpload
end
----------------------------------------------------------------
-- Callins
----------------------------------------------------------------



local btninstance = nil


function widget:Initialize()
	makeRectRoundVBO()
	makeShaders()
	
	rectRoundVAO = gl.GetVAO()
	
	rectRoundVAO:AttachVertexBuffer(rectRoundVBO.instanceVBO)
	rectRoundVBO.instanceVAO = rectRoundVAO
	
	WG['flowui_instancevbo'] = rectRoundVBO
	WG['flowui_shader'] = rectRoundShader
	WG['flowui_draw'] = Draw

	--[[for k = 1 , 1000 do
		local x = math.floor(math.random()*vsx)
		local y = math.floor(math.random()*vsy)
		local w = x+math.floor(math.random()*200+20)
		local h = y+math.floor(math.random()*150+10)
		btninstance = Draw.Button(rectRoundVBO, nil, 0.4, x,y,w,h, 1,1,1,1, 1,1,1,1, nil, { 0.035, 0.4, 0.035, 0.8 }, { 0.05, 0.6, 0.5, 0.8 },  WG.FlowUI.elementCorner*0.4)
	end]]--	

	--Draw.Button(rectRoundVBO, nil, 0.4, 500,0,1524,1000, 24,24,32,60, 1,1,1,1, nil, { math.random(), math.random(), math.random(), 0.8 }, { math.random(), math.random(), math.random(), 0.8 },  WG.FlowUI.elementCorner*0.4)
	font = WG['fonts'].getFont(nil, 1.4, 0.35, 1.4)
	if WG['buildmenu'] then
		if WG['buildmenu'].getGroups then
			groups, unitGroup = WG['buildmenu'].getGroups()
		end
	end
	if Script.LuaRules('GetIconTypes') then
		local iconTypesMap = Script.LuaRules.GetIconTypes()
		for udid, unitDef in pairs(UnitDefs) do
			if unitDef.iconType and iconTypesMap[unitDef.iconType] then
				unitIcon[udid] = iconTypesMap[unitDef.iconType]
			end
		end
	end
	
	if atlasID == nil then 
		atlasID = WG['flowui_atlas'] 
		atlassedImages = WG['flowui_atlassedImages'] 
	end
	
	makebuttonarray()
	makeunitbuttonarray()
end

function widget:Shutdown()
	WG['flowui_instancevbo'] = nil
	WG['flowui_shader'] = nil
	WG['flowui_draw'] = nil

	if rectRoundShader then
		rectRoundShader:Finalize()
	end
end

elems = 0

function widget:Update()
	local mx, my, left, middle, right = Spring.GetMouseState()
	uiUpdate(mx, my, left, middle, right)
end

function widget:DrawScreen()
	if atlasID == nil then 
		atlasID = WG['flowui_atlas'] 
		atlassedImages = WG['flowui_atlassedImages'] 
		Spring.Debug.TableEcho({gl.GetAtlasTexture(atlasID, "unitpics/armcom.dds")})
	end
	if elems < 3  then
		elems = elems+1
		local x = math.floor(math.random()*vsx) 
		local y = math.floor(math.random()*vsy)
		local s = math.floor(math.random()*35+70)
		local w = x+s*2
		local h = y+s
		local r = math.random()
		if r < 0.1 then
			--btninstance = Draw.Button(rectRoundVBO, nil, 0.4, x,y,w,h, 1,1,1,1, 1,1,1,1, nil, { math.random(), math.random(), math.random(), 0.8 }, { math.random(), math.random(), math.random(), 0.8 },  WG.FlowUI.elementCorner*0.4)
		elseif r < 0.2 then
			btninstance = Draw.Button(rectRoundVBO, nil, 0.4, x,y,w,h, 1,1,1,1, 1,1,1,1, nil, { 0, 0, 0, 0.8 }, {0.2, 0.8, 0.2, 0.8 }, WG.FlowUI.elementCorner * 0.5)
			--Draw.SelectHighlight(rectRoundVBO, nil, 0.5, x,y,w,h,1)
		elseif r < 0.3 then
			Draw.Selector(rectRoundVBO, nil, 0.5, x,y,w,h)
		elseif r < 0.4 then
			Draw.Slider(rectRoundVBO, nil, 0.5, x,y,w,h, 10, 1, 11)
		elseif r < 0.6 then
			Draw.SliderKnob(rectRoundVBO, nil, 0.5, x,y,s)

		elseif r < 0.7 then
			Draw.Toggle(rectRoundVBO, nil, 0.5, x,y,w,h, true)
			
		elseif r < 0.8 then
			--Draw.TexturedRectRound(rectRoundVBO, nil, 0.5, x,y,w,h, 10,1,1,1,1,nil,nil,nil,"icons/armpwt4.png")
			Draw.Element(
			rectRoundVBO, nil, 0.5, x,y,w,h, 
				1,1,1,1,
				1,1,1,1,
				nil,
				{ 0, 0, 0, 0.8 }, { 0.2, 0.8, 0.2, 0.8 },nil
			
			)
		elseif r < 0.9 then

			Draw.Unit(rectRoundVBO, nil, 0.5, x,y,w,y+2*s, 20, 
			1,1,1,1,
			1, nil, 0.8, -- zoom, bordersize, borderOpacity
			"unitpics/corcom.dds", 
			"icons/bantha.png",
			"luaui/images/flowui_gl4/metal.png", --grouptexture
			500, 7)
	
		elseif r < 1.0 then 
			Draw.Scroller( rectRoundVBO, nil, 0.5, x,y,x+s/2,y+2*s, 1000, 20)
		end
	end
	--local UiButton = WG.FlowUI.Draw.Button
	--UiButton(500, 500, 600, 550, 1,1,1,1, 1,1,1,1, nil, { 0, 0, 0, 0.8 }, { 0.2, 0.8, 0.2, 0.8 }, WG.FlowUI.elementCorner * 0.5)
	if chobbyInterface then return end
	
	
	if rectRoundVBO.dirty then uploadAllElements(rectRoundVBO) end -- do updates!
	--gl.Blending(GL.SRC_ALPHA, GL.ONE) -- bloomy
	gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA) -- regular
	gl.Texture(0, "luaui/images/backgroundtile.png")
	gl.Texture(1, atlasID)
	rectRoundShader:Activate()
	rectRoundVAO:DrawArrays(GL.POINTS)
	rectRoundShader:Deactivate()
	gl.Texture(1, false)
	gl.Texture(0, false)
	DrawText()
end
