
package.preload[ "core/anim" ] = function( ... )
-- anim.lua
-- Author: Vicent Gong
-- Date: 2012-09-21
-- Last modification : 2015-12-08
-- Description: provide basic wrapper for anim variables


--------------------------------------------------------------------------------
-- anim是一个动态值，在引擎运行期间动态变化的整数或浮点数值。可以理解为是一个“随时间不断变化的值”。  
-- 常用于做定时器和动画， 或者与@{core.prop}、shader等结合使用.
-- 
-- 概念介绍：
-- ---------------------------------------------------------------------------------------
--
--<a name="001" id="001" ></a>
-- **1.anim的当前值**
-- 
-- anim是一个随时间不断变化的值，某一时刻anim的取值即为当前值。可以通过@{#AnimBase.getCurValue}来获得。
--
--
-- **2.anim 中的类**
-- 
-- （1）@{#AnimBase}（anim的基类，**无法直接使用**）：定义了一些通用的接口。
-- 
-- （2）@{#AnimInt}：继承自@{#AnimBase}，其当前值是随时间均匀变化的**整数值**。
-- 
-- （3）@{#AnimDouble}：继承自@{#AnimBase}，其当前值是随时间均匀变化的**浮点值**。
-- 
-- （4）@{#AnimIndex}：继承自@{#AnimBase}，需要自定义数组，其数组的索引值是随时间均匀变化，但是当前值是取此刻的索引值所对应的值。
-- 
-- <a name="003" id="003" ></a>
-- **3.anim的变化类型**
-- 
-- anim会指定起始值和结束值，然后根据anim的变化类型来变化当前值。anim有以下三种变化类型：
-- 
-- * [```kAnimNormal```](core.constants.html#kAnimNormal)：从起始值变化到结束值即结束。整个过程只执行一次。 
-- 
-- * [```kAnimRepeat```](core.constants.html#kAnimRepeat)：从起始值变化到结束值，再从起始值变化到结束值，如此反复。
-- 
-- * [```kAnimLoop```](core.constants.html#kAnimLoop)：从起始值变化到结束值，再变化到起始值，再变化到结束值，如此反复。 
-- 
-- 
-- <a name="004" id="004" ></a>
-- **4.anim的回调函数的参数及意义**
-- 
-- 回调函数的参数 ```func(object,anim_type, anim_id, repeat_or_loop_num)```
-- 
-- * ```object``` :  @{#AnimBase.setEvent}的obj传入。
-- 
-- * ```anim_type```: anim的变化类型。由注册该回调函数的对象的构造函数传入。
-- 
-- * ```anim_id```:注册该回调的anim对象的id，此id由引擎自动分配。
-- 
-- * ```repeat_or_loop_num``` :循环的次数，此值由引擎传回。
-- 
-- 
-- 
-- @module core.anim
-- @return #nil 
-- @usage require("core/anim")

require("core/object");
require("core/constants");
require("core/global");

---------------------------------------------------------------------------------------------
-----------------------------------[CLASS] AnimBase------------------------------------------
---------------------------------------------------------------------------------------------

---
-- AnimBase提供一个“随时间不断变化的值”. 
-- 包含唯一标识、获取当前值、当前值变化的事件的函数.常用于做定时器或者UI动画.  
-- **这是个可变值类的基类，无法直接使用.**
--
-- @type AnimBase
AnimBase = class();

---
-- 返回AnimBase对象的唯一标识Id.
-- 
-- 每个AnimBase对象都有自己唯一的Id，是一个32位带符号整数，在创建对象的时候由引擎自动分配；
-- 可以用此Id对AnimBase对象进行操作.
--
-- @function [parent=#AnimBase] getID
-- @param self
-- @return #number AnimBase对象的Id.
property(AnimBase,"m_animID","ID",true,false);

---
-- 构造函数.
--
-- @param self
AnimBase.ctor = function(self)
	self.m_animID = anim_alloc_id();
	self.m_eventCallback = {};
end

---
-- 析构函数.
--
-- @param self
AnimBase.dtor = function(self)
	anim_free_id(self.m_animID);
end

---
-- 设置一个DebugName,便于调试.如果出现错误日志中会打印出这个名字，便于定位问题.
-- 
-- @param self
-- @param #string name 设置的debugName.
AnimBase.setDebugName = function(self, name)	
    self.m_debugName=name or ""
	anim_set_debug_name(self.m_animID,self.m_debugName);
end

---
-- 返回DebugName,便于调试.
-- 
-- @param self
-- @return #string DebugName.
AnimBase.getDebugName = function(self)
    return self.m_debugName
end


---
-- 获取AnimBase对象的当前值.<a href="#001">详见：anim的当前值。</a>
--
-- @param self
-- @param #number defaultValue 默认值。如果无法获取当前值，则返回这个默认值.    
-- @return #number AnimBase对象的当前值.如果当前值获取失败则返回默认值。如果默认值（```defaultValue```）为nil，获取失败返回0.    
AnimBase.getCurValue = function(self, defaultValue)
	return anim_get_value(self.m_animID,defaultValue or 0)
end

---
-- 设置AnimBase对象回调函数. 
--
-- @param self
-- @param obj 会在回调的时候当做回调函数的第一个参数传入,obj为任意类型.
-- @param #function func  当AnimBase对象当前值完成一次变化后，就会回调此函数.  <a href="#004">详见：anim的回调函数的参数及意义。</a>   
-- 
AnimBase.setEvent = function(self, obj, func)
	anim_set_event(self.m_animID,kTrue,self,self.onEvent);
	self.m_eventCallback.obj = obj;
	self.m_eventCallback.func = func;
end

--------------- private functions, don't use these functions in your code -----------------------

---
-- 向引擎底层注册的回调函数.
--**此方法被标记为private,开发者不应直接使用此方法，**
--而是使用@{#AnimBase.setEvent}来注册自己的回调函数.
--
-- @param self
-- @param #number anim_type anim的变化类型.<a href="#003">详见：anim的变化类型。</a>       
-- 
-- @param #number anim_id AnimBase对象的唯一标识Id.
-- @param #number repeat_or_loop_num 循环的次数，此值由引擎传回.  
AnimBase.onEvent = function(self, anim_type, anim_id, repeat_or_loop_num)
	if self.m_eventCallback.func then
		 self.m_eventCallback.func(self.m_eventCallback.obj,anim_type, anim_id, repeat_or_loop_num);
	end
end


---------------------------------------------------------------------------------------------
-----------------------------------[CLASS] AnimDouble----------------------------------------
---------------------------------------------------------------------------------------------

---
-- AnimDouble提供一个其当前值是随时间**均匀**变化的**浮点值**。      
--
-- @type AnimDouble
-- @extends #AnimBase
AnimDouble = class(AnimBase);

---
-- 构造函数.   
-- @param self
-- @param #number animType anim的变化类型.<a href="#003">详见：anim的变化类型。</a>.      
-- @param #number startValue 起始值。当前值从startValue开始变化, 取值范围(double)`[－1.797693E+308,1.797693E+308]`(十进制表示).
-- @param #number endValue 结束值。当前值在endValue终止或进入下一循环,  取值范围(double)`[－1.797693E+308,1.797693E+308]`(十进制表示).
-- @param #number duration 持续时间。即当前值变化从startValue变化到endValue时长。单位：毫秒。  取值范围(int) `[-2147483648，2147483647]`.
-- @param #number delay 延迟多长时间开始变化当前值。单位：毫秒。若delay为负或为空，则默认为0.  取值范围(int)`[-2147483648，2147483647]`.  
-- 
-- 
-- 例，当startValue=1，endValue=10，duration=10,delay=1000 时，```animType```不同取值所对应的情况如下：
--     
-- 1.```animType```取值为[```kAnimNormal```](core.constants.html#kAnimNormal)时，当前值在时间范围内从起始值线性变化到结束值后即停止。其当前值的变化如下：
-- 
-- &nbsp;&nbsp; 1.0、2.0…9.0、10.0;  
--    
-- 2.```animType```取值为[```kAnimRepeat```](core.constants.html#kAnimRepeat)时，当前值在时间范围内从起始值线性变化到结束值后,再从起始值线性变化到结束值，一直循环直到手动停止。其当前值的变化如下： 
--      
-- &nbsp;&nbsp; 1.0、2.0…9.0、10.0、1.0、2.0…10.0、1.0、2.0…10.0……;    
-- 
-- 3.```animType```取值为[```kAnimLoop```](core.constants.html#kAnimLoop)时，当前值在时间范围内从起始值线性变化到结束值后，再从结束值变化到起始值，一直反复直到手动停止。其当前值的变化如下：
--   
-- &nbsp;&nbsp; 1.0、2.0…9.0、10.0、9.0、8.0…2.0、1.0、2.0、3.0……10.0……;
AnimDouble.ctor = function(self, animType, startValue, endValue, duration, delay)
	anim_create_double(0, self.m_animID, animType, startValue, endValue, duration,delay or 0);
end

---
-- 析构函数.
--
-- @param self
AnimDouble.dtor = function(self)
	anim_delete(self.m_animID);
end


---------------------------------------------------------------------------------------------
-----------------------------------[CLASS] AnimInt-------------------------------------------
---------------------------------------------------------------------------------------------

---
-- AnimInt提供一个其当前值是随时间**均匀**变化的**整数值**。
--
-- @type AnimInt
-- @extends #AnimBase
AnimInt = class(AnimBase);

---
-- 构造函数.   
-- @param self
-- @param #number animType anim的变化类型.<a href="#003">详见：anim的变化类型。</a>.       
-- @param #number startValue 起始值。当前值从startValue开始变化,取值范围(int) `[-2147483648，2147483647]` (十进制表示)。 
-- @param #number endValue 结束值。当前值在endValue终止或进入下一循环, 取值范围(int) `[-2147483648，2147483647]` (十进制表示)。 
-- @param #number duration 持续时间。即当前值变化从startValue变化到endValue时长。单位：毫秒。  取值范围(int) `[-2147483648，2147483647]`.
-- @param #number delay 延迟多长时间开始变化当前值。单位：毫秒。若delay为负或为空，则默认为0.  取值范围(int)`[-2147483648，2147483647]`.   
-- 
-- 
-- 例，当startValue=1，endValue=10，duration=10,delay=1000 时，```animType```不同取值所对应的情况如下：
--     
-- 1.```animType```取值为[```kAnimNormal```](core.constants.html#kAnimNormal)时，当前值在时间范围内从起始值线性变化到结束值后即停止。其当前值的变化如下：
-- 
-- &nbsp;&nbsp; 1、2…9、10;  
--    
-- 2.```animType```取值为[```kAnimRepeat```](core.constants.html#kAnimRepeat)时，当前值在时间范围内从起始值线性变化到结束值后,再从起始值线性变化到结束值，一直循环直到手动停止。其当前值的变化如下： 
--      
-- &nbsp;&nbsp; 1、2…9、10、1、2…10、1、2…10……;    
-- 
-- 3.```animType```取值为[```kAnimLoop```](core.constants.html#kAnimLoop)时，当前值在时间范围内从起始值线性变化到结束值后，再从结束值变化到起始值，一直反复直到手动停止。其当前值的变化如下：
--   
-- &nbsp;&nbsp; 1、2…9、10、9、8…2、1、2、3……10……;
-- 
AnimInt.ctor = function(self, animType, startValue, endValue, duration, delay)
	anim_create_int(0, self.m_animID, animType, startValue, endValue, duration,delay or 0);
end

---
-- 析构函数.
-- 
-- @param self
AnimInt.dtor = function(self)
	anim_delete(self.m_animID);
end


---------------------------------------------------------------------------------------------
-----------------------------------[CLASS] AnimIndex-----------------------------------------
---------------------------------------------------------------------------------------------

---
-- AnimIndex是自定义的对象.该对象由用户提供一个数组，其索引值随时间均匀变化，而当前值是索引所对应的值 .  
-- 
-- 当前值不断从此数组中依次取出 ,用户可以在某一时刻来获取此值.      
-- 常用于做定时器或者UI动画.适用于动画不是匀速变化的情况.
--
-- @type AnimIndex
-- @extends #AnimBase
AnimIndex = class(AnimBase);

---
-- 构造函数.
-- @param self
-- @param #number animType anim的变化类型.<a href="#003">详见：anim的变化类型。</a>.     
-- @param #number startValue **索引**的起始值。  取值范围(int)`[-2147483648，2147483647]`.
-- @param #number endValue **索引**终止值。  取值范围(int)`[-2147483,648，2147483647]`.
-- @param #number duration **索引**值从startValue变化到endValue时长(单位：毫秒)。 取值范围(int)`[-2147483648，2147483647]`.
-- @param core.res#ResBase res 使用者提供可供取值的数组.  类型包括[```ResIntArray```](core.res.html#ResIntArray)、
-- [```ResDoubleArray```](core.res.html#ResDoubleArray)、
-- [```ResUShortArray```](core.res.html#ResUShortArray).  
-- @param #number delay 延迟多少时间开始索引值的变化.若delay为负或为空，则默认为0.  取值范围(int)`[-2147483648，2147483647]`.  
-- 
-- 
-- 例，当startValue=1，endValue=10，duration=10,delay=1000 时，res为[```ResDoubleArray```](core.res.html#ResDoubleArray)，其所对应的数组为{1.2,2.5,0.1,0.8,4.6,3.1,5.0,1.3,9.0,1.0}。 ```animType```不同取值所对应的情况如下：
--     
-- 1.```animType```取值为[```kAnimNormal```](core.constants.html#kAnimNormal)时，索引值在时间范围内从起始值线性变化到结束值后即停止。其**索引值**的变化如下：
-- 
-- &nbsp;&nbsp; 1、2…9、10;  
--    
-- **当前值**的变化如下：
-- 
-- &nbsp;&nbsp; 1.2、2.5、… 9.0、 1.0;
--    
-- 2.```animType```取值为[```kAnimRepeat```](core.constants.html#kAnimRepeat)时，索引值在时间范围内从起始值线性变化到结束值后,再从起始值线性变化到结束值，一直循环直到手动停止。其**索引值**的变化如下： 
--      
-- &nbsp;&nbsp; 1、2 … 9、10、1、2  …  9、10……;
-- 
-- **当前值**的变化如下：   
-- 
-- &nbsp;&nbsp;1.2、2.5、… 9.0、 1.0、1.2、2.5、… 9.0、1.0…… 
-- 
-- 3.```animType```取值为[```kAnimLoop```](core.constants.html#kAnimLoop)时，索引值在时间范围内从起始值线性变化到结束值后，再从结束值变化到起始值，一直反复直到手动停止。其**索引值**的变化如下：
--   
-- &nbsp;&nbsp; 1、2  … 9、10、9、 8  … 2、1、 2……
-- 
-- **当前值**的变化如下：
-- 
-- &nbsp;&nbsp; 1.2、2.5、… 9.0、1.0、 9.0、1.3、… 2.5、1.2、2.5……
-- 
AnimIndex.ctor = function(self, animType, startValue, endValue, duration, res, delay)
	anim_create_index(0, self.m_animID, animType, startValue, endValue, duration, res.m_resID,delay or 0); 
end


---
-- 析构函数.
-- 
-- @param self
AnimIndex.dtor = function(self)
	anim_delete(self.m_animID);
end
end
        

package.preload[ "core.anim" ] = function( ... )
    return require('core/anim')
end
            

package.preload[ "core/blend" ] = function( ... )
---
-- 设置drawing的混合模式
--
-- @param #number iDrawingId 
-- @param #number src 取值：(`kZero`, `kOne`, `kDstColor`等)。见@{core.constants} 
-- @param #number dst 取值：(`kZero`, `kOne`, `kSrcColor`等)。见@{core.constants} 
function drawing_set_blend_mode ( iDrawingId, src, dst )
	if dst == 7 then 
		print_string("==========目标因子不能为kSrcColor, 请修正==========");
		return
	end
	drawing_set_blend_factor ( iDrawingId,  src, dst );
end
end
        

package.preload[ "core.blend" ] = function( ... )
    return require('core/blend')
end
            

package.preload[ "core/constants" ] = function( ... )
-- constants.lua
-- Author: Vicent Gong
-- Date: 2012-09-21
-- Last modification : 2013-07-02
-- Description: Babe kernel Constants and Definition

--------------------------------------------------------------------------------
-- 常用常量
--
-- @module core.constants
-- @return #nil 
-- @usage require("core/constants")


---------------------------------------Anim---------------------------------------

--- anim完成后即停止。
kAnimNormal	= 0;
--- anim会无限重复。
kAnimRepeat	= 1;
--- anim完成一次后倒序一次，如此反复。
kAnimLoop	    = 2;
----------------------------------------------------------------------------------

---------------------------------------Res----------------------------------------
--format

--- RGBA8888（32位像素格式）。
kRGBA8888	= 0;
--- RGBA4444（16位像素格式）。
kRGBA4444	= 1;
--- RGBA5551（16位像素格式）。
kRGBA5551	= 2;
--- RGB565 （16位像素格式）。
kRGB565		= 3;

--filter

--- 最临近插值。
kFilterNearest	= 0;
--- 线性过滤。
kFilterLinear	= 1;
----------------------------------------------------------------------------------

---------------------------------------Prop---------------------------------------
--for rotate/scale

--- 用于PropRotate/PropScale，以drawing的左上角为中心点。
kNotCenter		= 0;
--- 以drawing中心点为中心。
kCenterDrawing	= 1;
--- 自定义中心点的位置，中心点的位置由坐标(x,y)决定。x,y的值是相对应drawing左上角的位置。
kCenterXY		= 2;
----------------------------------------------------------------------------------

--------------------------------------Align--------------------------------------

--- 居中对齐。
kAlignCenter		= 0;
--- 顶部居中对齐。
kAlignTop			= 1;
--- 右上角对齐。
kAlignTopRight		= 2;
--- 右部居中对齐。
kAlignRight	    = 3;
--- 右下角对齐。
kAlignBottomRight	= 4;
--- 下部居中对齐。
kAlignBottom		= 5;
--- 左下角对齐。
kAlignBottomLeft	= 6;
--- 左部居中对齐。
kAlignLeft			= 7;
--- 左上角对齐。
kAlignTopLeft		= 8;
---------------------------------------------------------------------------------

---------------------------------------Text---------------------------------------
--TextMulitLines

--- 单行文字。
kTextSingleLine	= 0;
--- 多行文字。
kTextMultiLines = 1;

--- 默认的字体名。
kDefaultFontName	= ""
--- 默认字号大小。
kDefaultFontSize 	= 24;

--- 默认文字颜色(红色分量)。
kDefaultTextColorR 	= 0;
--- 默认文字颜色(绿色分量)。
kDefaultTextColorG 	= 0;
--- 默认文字颜色(蓝色分量)。
kDefaultTextColorB 	= 0;
----------------------------------------------------------------------------------

---------------------------------------Touch--------------------------------------

--- 手指按下事件。
kFingerDown		= 0;
--- 手指移动事件。
kFingerMove		= 1;
--- 手指抬起事件。
kFingerUp		= 2;
--- 特殊事件。
kFingerCancel	= 3;
----------------------------------------------------------------------------------

---------------------------------------Focus--------------------------------------

--- 获得焦点。
kFocusIn 	= 0;
--- 失去焦点。
kFocusOut 	= 1;
----------------------------------------------------------------------------------

---------------------------------------Scroll-------------------------------------

--- scroller开始滚动。
kScrollerStatusStart	= 0;
--- scroller正在滚动。
kScrollerStatusMoving	= 1;
--- scroller停止滚动。
kScrollerStatusStop		= 2;
----------------------------------------------------------------------------------



-------------------------------------Bool values-----------------------------------

---对应c++的true。
kTrue 	= 1;
---对应c++的false。
kFalse 	= 0;
-----------------------------------------------------------------------------------


-------------------------------------Direction-------------------------------------

--- 水平方向(用于部分滚动类控件)。
kHorizontal 	= 1;
--- 竖直方向(用于部分滚动类控件)。
kVertical 		= 2;
-----------------------------------------------------------------------------------

---------------------------------------Platform------------------------------------
--ios

---480x320分辨率。
kScreen480x320		= "480x320"
---960x640分辨率。
kScreen960x640		= "960x640"
---1024x768分辨率。
kScreen1024x768	= "1024x768"
---2048x1536分辨率。
kScreen2048x1536	= "2048x1536"

--android

---1280x720分辨率。
kScreen1280x720	= "1280x720"
---1280x800分辨率。
kScreen1280x800	= "1280x800"
---1024x600分辨率。
kScreen1024x600	= "1024x600"
---960x540分辨率。
kScreen960x540		= "960x540"
---854x480分辨率。
kScreen854x480		= "854x480"
---800x480分辨率。
kScreen800x480		= "800x480"

--platform

--- ios平台(@{core.system#System.getPlatform}的返回值)
kPlatformIOS 		= "ios";
--- android平台(@{core.system#System.getPlatform}的返回值)
kPlatformAndroid 	= "android";
--- wp8平台(@{core.system#System.getPlatform}的返回值)
kPlatformWp8 		= "wp8";
--- win32平台(@{core.system#System.getPlatform}的返回值)
kPlatformWin32 		= "win32";
-----------------------------------------------------------------------------------



---------------------------------------Custom Blend--------------------------------

--- blend混合，见 [```drawing_set_blend_mode```](core.blend.html#drawing_set_blend_mode)
-- 
 
---取引擎默认的混合模式。不同情况下此取值可能不同。
kDefault  = 0;
---混合因子全置零。详见：[blend的公式。](http://engine.by.com:8080/hosting/data/1454473133632_6371758722883492571.html)
kZero = 1;
---混合因子全置1。详见：[blend的公式。](http://engine.by.com:8080/hosting/data/1454473133632_6371758722883492571.html)
kOne = 2;
---取源像素的Alpha作为混合因子。详见：[blend的公式。](http://engine.by.com:8080/hosting/data/1454473133632_6371758722883492571.html)
kSrcAlpha = 3;
---取目标像素的Alpha作为混合因子。详见：[blend的公式。](http://engine.by.com:8080/hosting/data/1454473133632_6371758722883492571.html)
kDstAlpha = 4;
---取（1-源像素的Alpha）作为混合因子。详见：[blend的公式。](http://engine.by.com:8080/hosting/data/1454473133632_6371758722883492571.html)
kOneMinusSrcAlpha = 5;
---取（1-目标像素的Alpha）作为混合因子。详见：[blend的公式。](http://engine.by.com:8080/hosting/data/1454473133632_6371758722883492571.html)
kOneMinusDstAlpha = 6;
---取源像素的RGB和Alpha作为混合因子。详见：[blend的公式。](http://engine.by.com:8080/hosting/data/1454473133632_6371758722883492571.html)
kSrcColor = 7;
---取目标像素的RGB和Alpha作为混合因子。详见：[blend的公式。](http://engine.by.com:8080/hosting/data/1454473133632_6371758722883492571.html)
kDstColor = 8;

----------------------------------------------------------------------------------

----------------------------------Input ------------------------------------------

--- 文字输入：任意内容(不应完全依赖于这些控制，因为部分输入法不会严格遵循这些规则)
kEditBoxInputModeAny  		= 0;
--- 文字输入：email地址
kEditBoxInputModeEmailAddr	= 1;
--- 文字输入：数字
kEditBoxInputModeNumeric	= 2;
--- 文字输入：电话号码
kEditBoxInputModePhoneNumber= 3;
--- 文字输入：网址
kEditBoxInputModeUrl		= 4;
--- 文字输入：小数
kEditBoxInputModeDecimal	= 5;
--- 文字输入：单行任意内容
kEditBoxInputModeSingleLine	= 6;


--- 文字输入：密码
kEditBoxInputFlagPassword					= 0;
--- 文字输入：关闭输入法单词联想
kEditBoxInputFlagSensitive					= 1;
--- 文字输入：单词首字母大写
kEditBoxInputFlagInitialCapsWord			= 2;
--- 文字输入：句子子首字母大写
kEditBoxInputFlagInitialCapsSentence		= 3;
--- 文字输入：所有字母大写
kEditBoxInputFlagInitialCapsAllCharacters	= 4;


--- 输入法确定按键显示为：(输入法的默认设置，一般为确定).
-- 这些文字一般会在strings.xml文件内重新定义
kKeyboardReturnTypeDefault = 0;
--- 输入法确定按键显示为：(不显示此按键)
kKeyboardReturnTypeDone = 1;
--- 输入法确定按键显示为：发送
kKeyboardReturnTypeSend = 2;
--- 输入法确定按键显示为：搜索
kKeyboardReturnTypeSearch = 3;
--- 输入法确定按键显示为：开始
kKeyboardReturnTypeGo = 4;


-----------------------------------------------------------------------------------


------------------------------------Android Keys-----------------------------------

---android上的back键的key。
kBackKey="BackKey";
---android的home键的key。
kHomeKey="HomeKey";
---暂停程序。
kEventPause="EventPause";
---恢复程序。
kEventResume="EventResume";
---退出程序。
kExit="Exit";
-----------------------------------------------------------------------------------



----------------------------------模板测试参数取值相关--------------------------------


---表示这次绘制区域中的像素片段总是通过模板测试。
kGL_ALWAYS      = 0
---表示这次绘制区域中的像素片段永不通过模板测试。
kGL_NEVER 	     = 1
---参考值小于模板缓冲区的对应的值则通过模板测试。
kGL_LESS        = 2
---参考值小于等于模板缓冲区的对应的值则通过模板测试。
kGL_LEQUAL      = 3
---参考值大于模板缓冲区的对应的值则通过模板测试。
kGL_GREATER     = 4
---参考值大于等于模板缓冲区的对应的值则通过模板测试。
kGL_GEQUAL      = 5
---参考值等于模板缓冲区的对应的值则通过模板测试。
kGL_EQUAL       = 6
---参考值不等于模板缓冲区的对应的值则通过模板测试。
kGL_NOTEQUAL    = 7


---保持当前的模板值不变。
kGL_KEEP		   = 0
---将当前的模板值设为0。
kGL_ZERO		   = 1
---将当前的模板值设置为参考值。
kGL_REPLACE	   = 2
---在当前的模板值上加1。
kGL_INCR	       = 3
---在当前的模板值上减1。
kGL_DECR   	   = 4



---------------------------------------Http---------------------------------------
--http get/post

--- http请求类型：get
kHttpGet		= 0;
--- http请求类型：post
kHttpPost		= 1;
--- http返回类型(这是唯一可用的类型)
kHttpReserved	= 0;
end
        

package.preload[ "core.constants" ] = function( ... )
    return require('core/constants')
end
            

package.preload[ "core/dict" ] = function( ... )
-- dict.lua
-- Author: Vicent Gong
-- Date: 2012-09-30
-- Last modification : 2013-05-29
-- Description: provide basic wrapper for dict functions

------------------------------------------------------------------------------
-- Dict 用于存储数据(程序内临时使用、与java/c++之间传数据、保存到文件内供下次使用等).
--
-- @module core.dict 
-- @return #nil
-- @usage require("core/dict")
require("core/object");
require("core/constants");

---
--Dict是用于在游戏中存储数据的类.
-- 数据可以临时使用，也可以直接保存到文件内供下次启动游戏继续使用。数据已key-value的方式保存在文件中。
-- @type Dict
Dict = class();

---
-- 构造函数.
-- 
-- win32下生成的文件在$(SolutionDir)/Resource/dict/中。
-- Android下生成的文件存储在SDCard/{package_name}/dict/中,以隐藏文件的形式存在。
-- 在Android中存储在扩展卡中，如果扩展卡不能访问应用程序将无法访问此文件。
-- 
-- @param self，调用者本身。
-- @param #string dictName dict的名字。此名字必全局唯一。
Dict.ctor = function(self, dictName)
	self.m_name = dictName;
end

---
-- 析构函数.
-- 
-- 只会释放Lua的的对象，不会删除本地文件。
-- @param self，调用者本身。
Dict.dtor = function(self)
	self.m_name = nil;
end

---
-- 从文件内加载上次保存的内容.
--
-- @param self，调用者本身。
Dict.load = function(self)
	return dict_load(self.m_name);
end

---
-- 将内容保存到文件内，以便下次启动程序还可以再取出.
-- 
-- @param self，调用者本身。
Dict.save = function(self)
	return dict_save(self.m_name);
end

---
-- 删除该dict的所有数据.
--
-- @param self，调用者本身。
Dict.delete = function(self)
	return dict_delete(self.m_name);
end

---
-- 存入一个boolean值.
--
-- @param self，调用者本身。
-- @param #string key 键(必须是一个合法的变量命名。必须是字母开头)。
-- @param #boolean value 值(除nil与false外其余都为存储为true)。
Dict.setBoolean = function(self, key, value)
	return dict_set_int(self.m_name,key,value and kTrue or kFalse);
end

---
-- 取出一个boolean值.
--
-- @param self，调用者本身。
-- @param #string key 键。
-- @param #boolean defaultValue 如果不存在此key，则返回defaultValue。
-- @return #boolean 如果key存在则返回对应的值，如果key值对应的值不存在且defaultValue为nil或false则返回为false，其余值返回true。 
Dict.getBoolean = function(self, key, defaultValue)
	local ret =  dict_get_int(self.m_name,key,defaultValue and kTrue or kFalse);
	return (ret == kTrue);
end

---
-- 存入一个int值.
--
-- @param self，调用者本身。
-- @param #string key 键(必须是一个合法的变量命名。必须是字母开头)。
-- @param #number value 值(必须是整型)。
Dict.setInt = function(self, key, value)
	return dict_set_int(self.m_name,key,value);
end

---
-- 取出一个int值.
-- 
-- @param self，调用者本身。
-- @param #string key 键。
-- @param #number defaultValue 如果不存在，则返回此默认值。
-- @return #number 值(整型)。如果不存在则返回defaultValue，如果defaultValue为nil，则返回0。
Dict.getInt = function(self, key, defaultValue)
	return dict_get_int(self.m_name,key,defaultValue or 0);
end

---
-- 存入一个double值. 
--
-- @param self，调用者本身。
-- @param #string key 键(必须是一个合法的变量命名。必须是字母开头)。
-- @param #number value 值(必须是number或者是可以转换为number的string)。
Dict.setDouble = function(self, key, value)
	return dict_set_double(self.m_name,key,value);
end

---
-- 取出一个double值. 
-- 
-- @param self，调用者本身。
-- @param #string key 键。
-- @param #number defaultValue 如果不存在，则返回此默认值。
-- @return #number 值(number)。如果不存在则返回defaultValue，如果defaultValue为nil，则返回0.0。
Dict.getDouble = function(self, key, defaultValue)
	return dict_get_double(self.m_name,key,defaultValue or 0.0);
end

---
-- 存入一个string值. 
--
-- @param self，调用者本身。
-- @param #string key 键(必须是一个合法的变量命名。必须是字母开头)。
-- @param #string value 值(必须是string或者是number)。
Dict.setString = function(self, key, value)
	return dict_set_string(self.m_name,key,value);
end

---
-- 取出一个string值. 
--
-- @param self，调用者本身。
-- @param #string key 键。
-- @return #string 取到的值，如果不存在，则返回""。
Dict.getString = function(self, key)
	return dict_get_string(self.m_name,key) or "";
end


---
--更改Dict文件夹下文件的后缀为extensionName.(接口不稳定，不建议使用)  
--每次调用Dict.setFileExtension将覆盖之前的调用.
--若加载的Dict文件（例如xxx.t)存在，则将该文件内容迁移到xxx.extensionName,  
--同时保留xxx.t.
--若加载文件不存在，则创建新文件.
--@param #string extensionName 新的后缀.
Dict.setFileExtension =  function (extensionName)
    dict_set_fileextension(extensionName)
end
end
        

package.preload[ "core.dict" ] = function( ... )
    return require('core/dict')
end
            

package.preload[ "core/drawing" ] = function( ... )
-- drawing.lua
-- Author: Vicent Gong
-- Date: 2012-09-21
-- Last modification : 2013-08-08
-- Description: provide basic wrapper for drawing

-------------------------------------------------------
--
-- widget是指可以绘制到屏幕上的绘制对象,即一个渲染实体.
--
-- 包括点、线、位图、多边形等。但绘制对象本身并不包含可绘制的数据，需要引用资源（详见：@{core.res}）的数据，它也不包含绘制的属性，添加属性时需引用属性（详见：@{core.prop}） 对象。任何一个按钮、图片、文字、滚动列表等都是一个widget或多个widget的组合。
--
-- 概念介绍：
-- ---------------------------------------------------------------------
--
-- **1.widget绘制对象。**
--
-- 引擎中的可绘制对象widget是用树型结构管理的，有如下特性：
--
--（1）对父节点的某些操作会影响子节点，比如：2D变化、可见性、裁剪、颜色；
--
--（2）树状结构定义了渲染次序；
--
--（3）缺省有一个根节点；
--
--
-- **2.类结构。**
-- 
--（1）@{#WidgetBase}（widget的基类，**无法直接使用**）：WidgetBase封装了一个基本绘制对象类，拥有绘制对象的一般属性。其它的绘制对象类都继承它的属性，它是所有其它绘制对象类的父类。
--
--（2）@{#FBONode}： FBONode继承自@{#WidgetBase}类，使用FBO自动缓冲自己以及子节点渲染的内容，内容不脏的清空下，只需要重新渲染FBO贴图本身。
--
--（3）@{#EffectsNode}： EffectsNode继承自@{#WidgetBase}类，在FBOWidget的基础上加上后处理特效列表的处理。 能正确处理三种不同程度的脏状态。
--
--（4）@{#LuaNode}：LuaNode继承自@{#WidgetBase}类，lua中定制Widget。
--
--（5）@{#DrawingBase}：DrawingBase继承自@{#WidgetBase}类,包含对绘制对象的旋转、平移、缩放、裁剪、透明度、颜色等的操作。
--
--（6）@{#DrawingImage}：DrawingImage继承自@{#DrawingBase}类，DrawingImage代表一个由图片（文本也是会先生成图片）构成的widget。
-- 
--（7）@{#DrawingEmpty}：DrawingEmpty继承自@{#DrawingBase}类，是渲染结构树上一个空节点，不渲染什么内容。
--
--
-- 提醒:@{#DrawingImage}和@{#DrawingEmpty}的差异极小，除了渲染内容上的差异，其操作方式、支持的功能几乎是完全相同的。
--
--
-- <a name="003" id="003" ></a>
-- **3.widget的id。**
--
-- 每一个widget的对象会有一个惟一的id来作为标识，在创建widget对象的时候，会为绘制对象自动分配一个id。
--
-- <a name="004" id="004" ></a>
-- 
-- **4.widget的添加。**
--
-- 由于引擎是用树形结构管理可绘制对象widget，所添加的widget对象最终会形成一颗可供渲染的树。widget对象在创建的时候，不会被添加到任何widget对象上，要通过以下两种方式来添加。
--
--（1）@{#WidgetBase.addToRoot}：将当前的widget添加到引擎内部创建的根节点（此根节点外部无法访问，只能通过这种方式添加）。只有被加到引擎内部创建的根节点的widget树，才会被绘制到屏幕上。
--
--（2）@{#WidgetBase.addChild}：给当前的widget添加一个子节点。
-- 
-- 
-- <a name="005" id="005" ></a>
-- **5.引擎的渲染顺序。**
-- 
-- 被添加的widget会形成一颗可供渲染的多叉树，在渲染之前，会对这颗树排序，然后渲染。每一个widget都有一个level（会影响同一级节点的绘制次序），level的默认值为0.
--
--
-- 1.渲染树的排序规则：
-- 
-- （1）同一级节点，level不同，按level从小到大排列，level越大，越后绘制。
-- 
-- （2）同一级节点，level相同，按节点添加的先后顺序排列，先添加的先绘制。
-- 
-- （3）后绘制节点的离视线近，它的触摸事件先被拾取。
-- 
-- 
-- 2.渲染树的遍历渲染（类似二叉树中的先序遍历）：
-- 
-- （1）引擎会从根开始渲染，然后按照根节点的直接子节点的排序依次渲染其相应的子树；
-- 
-- （2）子树的渲染规则也是先渲染父节点，然后根据其直接子节点的排序渲染相应的子树。
-- 
-- 
-- 举例：
-- 
--（1）未设置level。每个widget默认的level为0。假设在下图中同一级节点，是从左到右的先后添加顺序（如B的直接子节点是先添加D，再添加E,再添加F）。
-- 
-- ![](http://engine.by.com:8080/hosting/data/1449819121053_3322571509346634203.png)
-- 
-- 根据排序规则和遍历渲染的方式,level相同，按节点先后顺序，先添加的先绘制。上图的绘制顺序为：A,B,D,I,K,E,J,F,C,G,L,M,O,H,N,P。
-- 
-- 
--（2）假设此时，通过@{#WidgetBase.setLevel}来设置上图中E节点的level = 2,那么，其树的结构即为：
--
-- ![](http://engine.by.com:8080/hosting/data/1449829607241_2915773254321814815.png)。
-- 
-- **注意：这个level只影响同一级的节点，也即其兄弟节点的绘制顺序**。根据排序规则和遍历渲染的方式，将**同一级节点**按照level从小到大来排序，如果level相同，那么按照节点的先后添加顺序。如上图中D，F,默认的level 都为0，E的level被设置为2，D，F节点D先添加，所以排序为D，F，E。
-- 
-- 因此,此树的渲染先后顺序即是A,B,D,I,K,F,E,J,C,G,L,M,O,H,N,P。
--
-- 3.在屏幕上的呈现是：先绘制的，离视线远，后绘制的离视线近。
-- 
-- 假设有两个widget对象widget1，widget2，先绘制widget2，后绘制widget1。那么其呈现的如下图：
-- 
--  ![](http://engine.by.com:8080/hosting/data/1458282969598_8105051804832588017.png)
-- 
-- 其中，widget1离视线近，widget2离视线远。
-- 
-- 
--
--<a name="006" id="006" ></a> 
-- **6.引擎的子节点与父节点九种对齐方式和其相对位置。**
--
--（1）引擎默认的对齐方式：[```kAlignTopLeft```](core.constants.html#kAlignTopLeft)（子节点的左上角与父节点的左上角对齐） 。
-- 
-- 如图：设置对齐方式为[```kAlignTopLeft```](core.constants.html#kAlignTopLeft)时，假设widget2为widget1的子节点，即子节点widget2的左上角点C与父节点widget1的左上角的点O对齐，此图中widget2相对与widget1的位置为x=70,y=50。
--
-- ![](http://engine.by.com:8080/hosting/data/1458283149313_8569170373993330336.png)
-- 
--（2）[```kAlignTop```](core.constants.html#kAlignTop)（子节点的顶部中点与父节点的顶部中点对齐）。
-- 
-- 如图：设置对齐方式为[```kAlignTop```](core.constants.html#kAlignTop)时，假设widget2为widget1的子节点，，即子节点widget2的顶部中点C与父节点widget1的顶部中点O对齐，此图中widget2相对与widget1的位置为x=120,y=15。
-- 
-- ![](http://engine.by.com:8080/hosting/data/1458283294051_2258314156613814351.png)
-- 
--（3）[```kAlignTopRight```](core.constants.html#kAlignTopRight)时（子节点的右上角与父节点的右上角对齐）。
-- 
-- 如图：设置对齐方式为[```kAlignTopRight```](core.constants.html#kAlignTopRight)时，假设widget2为widget1的子节点，，即子节点widget2的右上角点C与父节点widget1的右上角点O对齐，此图中widget2相对与widget1的位置为x=25,y=30。
-- 
-- ![](http://engine.by.com:8080/hosting/data/1458283390487_8191936367900965076.png)
-- 
--（4）[```kAlignLeft```](core.constants.html#kAlignLeft)（子节点的左边中点与父节点的左边中点对齐）。
-- 
-- 如图：设置对齐方式为[```kAlignLeft```](core.constants.html#kAlignLeft)时，假设widget2为widget1的子节点，，即子节点widget2的左边中点C与父节点widget1的左边中点O对齐，此图中widget2相对与widget1的位置为x=80,y=70。
-- 
-- ![](http://engine.by.com:8080/hosting/data/1458283495733_740989466333232062.png)
-- 
--（5）[```kAlignCenter```](core.constants.html#kAlignCenter)（子节点的中心点与父节点的中心点对齐）。
-- 
-- 如图：设置对齐方式为[```kAlignCenter```](core.constants.html#kAlignCenter)时，假设widget2为widget1的子节点，，即子节点widget2的中心点C与父节点widget1的中心点O对齐，此图中widget2相对与widget1的位置为x=87,y=65。
-- 
-- ![](http://engine.by.com:8080/hosting/data/1458283617514_2163928432965703413.png)
-- 
--（6）[```kAlignRight```](core.constants.html#kAlignRight)（子节点的右边中点与父节点的右边中点对齐）。
-- 
-- 如图：设置对齐方式为[```kAlignRight```](core.constants.html#kAlignRight)时，假设widget2为widget1的子节点，，即子节点widget2的右边中点C与父节点widget1的右边中点O对齐，此图中widget2相对与widget1的位置为x=50,y=63。
-- 
-- ![](http://engine.by.com:8080/hosting/data/1458283714896_2982191270447364557.png)
-- 
--（7）[```kAlignBottomLeft```](core.constants.html#kAlignBottomLeft)（子节点的左下角与父节点的左下角对齐）。
-- 
-- 如图：设置对齐方式为[```kAlignBottomLeft```](core.constants.html#kAlignBottomLeft)时，假设widget2为widget1的子节点，，即子节点widget2的左下角点C与父节点widget1的左下角点O对齐，此图中widget2相对与widget1的位置为x=69,y=57。
-- 
-- ![](http://engine.by.com:8080/hosting/data/1458283790096_8131772643493323992.png)
-- 
--（8）[```kAlignBottom```](core.constants.html#kAlignBottom)（子节点的底部中点与父节点的底部中点对齐）。
--
-- 如图：设置对齐方式为[```kAlignBottom```](core.constants.html#kAlignBottom)时，假设widget2为widget1的子节点，，即子节点widget2的底部中点C与父节点widget1的底部中点O对齐，此图中widget2相对与widget1的位置为x=91,y=47。
-- 
-- ![](http://engine.by.com:8080/hosting/data/1458283942940_1356091180631021029.png)
-- 
--（9）[```kAlignBottomRight```](core.constants.html#kAlignBottomRight)（子节点的右下角与父节点的右下角对齐）。
-- 
-- 如图：设置对齐方式为[```kAlignBottomRight```](core.constants.html#kAlignBottomRight)时，假设widget2为widget1的子节点，，即子节点widget2的右下角点C与父节点widget1的右下角点O对齐，此图中widget2相对与widget1的位置为x=42,y=30。
-- 
-- ![]( http://engine.by.com:8080/hosting/data/1458284015988_1795585246403404752.png)
-- 
-- <a name="007" id="007" ></a>
--  **7.widget属性。** (注：这个属性是引擎独有的一个概念，不同于@{WidgetBase:}里的一些setXXX()方法)。
--  
--  可以给widget添加一些属性值。如颜色、点大小、线宽、透明度、2D变化（平移、旋转、缩放）、索引等等。
--  
--  1.widget分为静态属性和动态属性两种：
--  
--  （1）静态属性（此属性是静态的，没有变化过程）。
--  
--  （2）动态属性（所谓动态，即是从指定的初始值动态变化到结束值的动态变化的呈现过程），也即动画。
--  <a name="00702" id="00702" ></a>    
--  
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;动态变化的方式有以下三种类型：
-- 
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[```kAnimNormal```](core.constants.html#kAnimNormal)  从初始值动态变化到结束值，只变化一次就停止。
-- 
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[```kAnimRepeat```](core.constants.html#kAnimRepeat) 从初始值动态变化到结束值，再从初始值动态变化到结束值，如此循环重复，直到手动停止。
-- 
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[```kAnimLoop```](core.constants.html#kAnimLoop) 从初始值动态变化到结束值，再从结束值动态变化到初始值，如此循环重复，直到手动停止。
--  
--  <a name="00703" id="00703" ></a> 
--  
--  2.在使用属性相关函数的时候，如何指定widget的中心点。
--  
--  [```kNotCenter```](core.constants.html#kNotCenter)，指定widget的左上角的点为中心点。
--  
--  [```kCenterDrawing```](core.constants.html#kCenterDrawing) 指定widget的中心的点为中心点。 
--  
--  [```kCenterXY```](core.constants.html#kCenterXY) 自定义中心点的位置，中心点的位置由坐标(x,y)决定。x,y的值是相对应widget左上角的位置。
--  
--  <a name="0070301" id="0070301" ></a> 
--  
--  widget左上角为原点的坐标系，如下图，点O即为widget的左上角，其坐标系如图所示：
--  
--  ![]( http://engine.by.com:8080/hosting/data/1458284089416_7206319639090477518.png)
--  
-- 3.当应用平移，旋转等属性的时候，其widget的的坐标系也会跟着进行平移旋转。 
--
--  
--  <a name="008" id="008" ></a> 
--  
--  **8.触摸机制回调函数的参数意义**（引擎只支持单点触控）。
--  
-- 1.回调函数的形式为：```func(obj, finger_action, x, y, drawing_id_first,drawing_id_current，event_time) ```
-- 
-- * ```obj``` 为任意类型。
-- 
-- * ```finger_action``` 的取值为：
-- 
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[```kFingerDown```](core.constants.html#kFingerDown)（手指下压事件）：对应android里的[ACTION_DOWN](http://developer.android.com/intl/zh-cn/reference/android/view/MotionEvent.html#ACTION_DOWN)。
-- 
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[```kFingerMove```](core.constants.html#kFingerMove)（手指移动事件）：对应android里的[ACTION_MOVE](http://developer.android.com/intl/zh-cn/reference/android/view/MotionEvent.html#ACTION_MOVE)。
-- 
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[```kFingerUp```](core.constants.html#kFingerUp)（手指抬起事件）：对应android里的[ACTION_UP](http://developer.android.com/intl/zh-cn/reference/android/view/MotionEvent.html#ACTION_UP)。
-- 
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[```kFingerCancel```](core.constants.html#kFingerCancel)（特殊情况）对应android里的[ACTION_CANCEL](http://developer.android.com/intl/zh-cn/reference/android/view/MotionEvent.html#ACTION_CANCEL)。
-- 
-- * x,y 是手指触摸时的全局坐标，即相对于<a href = "#010">屏幕左上角</a>的绝对坐标。
-- 
-- * ```drawing_id_first``` 是[```kFingerDown```](core.constants.html#kFingerDown)时拾取到的widget可绘制对象的id。
-- 
-- * ```drawing_id_current``` 是引擎根据当前坐标拾取到的widget可绘制对象的id。
-- 
-- * ```event_time``` 当前事件的触发时间(单位：毫秒)。**注：此值不同系统会有不同，仅仅可以用于计算时间差，不可以用于决定系统时间。这个值和帧时间是不同的概念，Android上是OS给出的手指事件的时间。**
-- 
-- 
-- 2.触摸事件的分发机制：
-- 
-- 引擎可以通过@{#WidgetBase:.setEventTouch}和@{#WidgetBase:.setEventDrag}来设置触摸相应的回调，但是这两者除了执行的先后顺序，其在本质上意义是一样的。
-- 
-- 触摸分发的规则:按照widget绘制顺序的相反顺序来分发消息，只有可拾取的且注册了@{#WidgetBase:.setEventTouch}或@{#WidgetBase:.setEventDrag}的回调的绘制对象才会得到响应。
-- 
-- 触摸事件分发的完整流程：
-- 
-- （1）当[```kFingerDown```](core.constants.html#kFingerDown)事件发生时，会有两条分发路径，
-- 
-- * 根据触摸点的位置，先通过widget绘制顺序的相反顺序来查找，当找到包含触摸点的**第一个可被拾取的并且注册了**@{#WidgetBase:.setEventTouch}的回调的widget，立即执行相应的[```kFingerDown```](core.constants.html#kFingerDown)里的逻辑，则结束此次查找，并记录此widget的id为```drawing_id_first```。
-- 
-- * 根据触摸点的位置，再通过widget绘制顺序的相反顺序来查找，当找到包含触摸点的**第一个可被拾取的并且注册了**@{#WidgetBase:.setEventDrag}的回调的widget，立即执行相应的[```kFingerDown```](core.constants.html#kFingerDown)里的逻辑，则结束此次查找，并记录此widget的id为```drawing_id_first```。 
-- 
-- 如下图，假设下图是一颗已经排好序的渲染树，其渲染顺序即是A,B,D,I,K,E,J,F,C,G,L,M,O,H,N,P。 可参考：<a href="#005">5.引擎的渲染顺序</a>
-- 
-- ![](http://engine.by.com:8080/hosting/data/1449819121053_3322571509346634203.png)
-- 
-- 触摸分发查找路径即为P,N,H,O,M,L,G,C,F,J,E,K,I,D,B,A（类似二叉树中的后序遍历）。
-- 
-- （2）当[```kFingerMove```](core.constants.html#kFingerMove)事件发生时，会根据[```kFingerDown```](core.constants.html#kFingerDown)时记录的```drawing_id_first```。
-- 
-- 先调用其相应的widget所注册的@{#WidgetBase:.setEventTouch}里的[```kFingerMove```](core.constants.html#kFingerMove) 相对应的逻辑。
-- 
-- 后调用其相应的widget所注册的@{#WidgetBase:.setEventDrag}里的[```kFingerMove```](core.constants.html#kFingerMove) 相对应的逻辑。
-- 
-- （3）当[```kFingerUp```](core.constants.html#kFingerUp)事件发生时(同[```kFingerMove```](core.constants.html#kFingerMove)),会根据[```kFingerDown```](core.constants.html#kFingerDown)时记录的```drawing_id_first```。
-- 
-- 先调用其相应的widget所注册的@{#WidgetBase:.setEventTouch}里的[```kFingerUp```](core.constants.html#kFingerUp) 相对应的逻辑。
-- 
-- 后调用其相应的widget所注册的@{#WidgetBase:.setEventDrag}里的[```kFingerUp```](core.constants.html#kFingerUp) 相对应的逻辑。
-- 
-- <a name="009" id="009" ></a> 
-- 
-- **9.九宫格图片**
-- 
-- 九宫格图片主要作用是用来拉伸图片，这样的好处在于保留图片四个角不变形的同时，对图片中间部分进行拉伸。
-- 
-- 如果是九宫格图片，通过@{#DrawingImage.ctor}的构造函数来初始化一张图片时，leftWidth,rightWidth,topWidth,bottomWidth四个参数必须保证至少有一个不是nil，其余的为nil的参数会被认为是0。
-- 
-- 传入的参数会将widget分为九个部分，如下图：
-- 
-- ![](http://engine.by.com:8080/hosting/data/1450255270531_3012031873394385778.png)
-- 
-- 图中1，3，7，9 这部分区域保持不变，只对2，4，5，6，8 这部分区域进行拉伸。
-- 
-- 
-- <a name="010" id="010" ></a> 
-- 
-- **10.引擎的屏幕坐标系。**
-- 
-- 如下图，屏幕左上角点O即为屏幕的原点。
-- 
-- ![](http://engine.by.com:8080/hosting/data/1450341504038_8276422489397085965.png)
-- 
-- 
-- <a name="011" id="011" ></a> 
-- 
-- **11.线性变换规律。**
-- 
-- 引擎里的一些值是呈线性变换，如下图，start值到end值是随着时间线性变化的。在n时刻的值为cur。
-- 
-- ![](http://engine.by.com:8080/hosting/data/1450343911364_8090642195104516583.png)
-- 
-- **12.引擎屏幕适配（文档中未提及部分都是未经过屏幕适配的）。**
-- 
-- 在main.lua中会有一个设计分辨率，最终的适配根据这个设置的分辨率来适配。
-- 
--    设置设计分辨率的代码如下：
-- 
--      function event_load(width,height)
--          System.setLayoutWidth(1280);
--          System.setLayoutHeight(720);
--      end
-- 
-- 
--    适配缩放的代码如下：
--    
--      System.getLayoutScale = function()
--          if not System.s_layoutScale then
--              local xScale = System.getScreenWidth() / System.getLayoutWidth();
--              local yScale = System.getScreenHeight() / System.getLayoutHeight();
--              System.s_layoutScale = xScale>yScale and yScale or xScale;
--          end
--          return System.s_layoutScale;
--      end 
-- 
-- System.getScreenWidth()是获得屏幕的宽度，详见：@{core.system#system.getScreenWidth}
-- 
-- 如果未设置过设计分辨率，则比例为1。
-- 否则为屏幕大小到设计分辨率大小的比例，以宽高中小的为准。    
-- 如设置widget的大小为w,h
-- 那么经过适配缩放的w = w * System.getLayoutScale(),h = h * System.getLayoutScale()。
-- 
-- @module core.drawing
-- @return nil
-- @usage require("core/drawing")


require("core/object");
require("core/constants");
require("core/anim");
require("core/prop");
require("core/system");
require("core/global");

---
-- widget的基类，**本类无法直接使用**.
-- WidgetBase封装了一个基本绘制对象类，拥有绘制对象的一般属性。其它的绘制对象类都继承它的属性，它是所有其它绘制对象类的父类。。
--
-- @type WidgetBase
WidgetBase = class();

---
-- 返回此widget对象的id.详见：<a href="#003">widget的id</a>
--
-- @function [parent=#WidgetBase] getID
-- @param self
--
-- @return #number widget的id。
property(WidgetBase,"m_drawingID","ID",true,false);

---
-- 构造函数.
--
-- @param self
WidgetBase.ctor = function(self)
    self.m_drawingID = drawing_alloc_id();

    self.m_align = kAlignTopLeft;
	self.m_x = 0;
	self.m_y = 0;
	self.m_width = 0;
	self.m_height = 0;
	self.m_alignX = 0;
	self.m_alignY = 0;
		
	self.m_visible = true;
	self.m_pickable = true;
	self.m_level = 0;

	self.m_children = {};
	self.m_rchildren = {};

    self._autoCleanup = {};

	self.m_eventCallbacks = {
		touch = {};
		drag = {};
		doubleClick = {};
	};
	
	local class = self.getWidgetClass()
    if class ~= nil then
        self.m_widget = class()
        self.m_widget:setId(self.m_drawingID)
    end

    self._animations = {}
end

---
-- 获取Widget类.
-- @return #Widget 返回Widget类。
WidgetBase.getWidgetClass = function(self)
    return Widget
end

---
-- 析构函数.
--
-- @param self
WidgetBase.dtor = function(self)
	--This is safe, only because the drawing is going to release;
	--Otherwise it should remove the prop first then release it.
	delete(self.m_doubleClickAnim);
	self.m_doubleClickAnim = nil;
    self.m_rchildren = {}
	  
    for _,v in pairs(self.m_children) do 
        delete(v);
    end

    local p = self.m_parent
	if p then
        local index = p.m_rchildren[self];
        if index then
            p.m_rchildren[self] = nil;
            p.m_children[index] = nil;
        end
		--WidgetBase.removeChild(self.m_parent,self);
	end

    self.m_children = {};

    self.m_touchEventCallbacks = {
		touch = {};
		drag = {};
		doubleClick = {};
	};

    self:stopAllAnimations()

    --This drawing_delete should actually be in derivded class dtor,
    --It is here because the children release.
    --It is ugly but useful,so keep it for now.
    drawing_delete(self.m_drawingID);
    drawing_free_id(self.m_drawingID);

    for _, w in ipairs(self._autoCleanup) do
        w:cleanup()
    end
    self._autoCleanup = {}
end

---
-- 设置一个debugName,便于调试.
-- 
-- 在出错的时候所打印出来的错误信息，会把debugName也给打印出来。
--
-- @param self
-- @param #string name debugName。
WidgetBase.setDebugName = function(self, name)
    self.m_debugName = name;
	drawing_set_debug_name(self.m_drawingID,name or "");
end


---
-- 返回debugName.
--
-- @param self
-- @return #string debugName。
WidgetBase.getDebugName = function(self)
  return self.m_debugName;
end

------------------------------------------Touch stuff ----------------------------------------------

---
-- 设置此widget是否可以响应手指触摸事件（是否可被拾取）.
-- 
-- 注意:
-- 
-- 如果widget是不可拾取，那么其相应的子节点也不会被拾取，不响应触摸事件
-- 
-- 如果widget是可拾取的，那么其相应的子节点是否可被拾取由其自己的设置决定。
-- 
-- @param self
-- @param #boolean pickable  pickable为true则可以被拾取，即可以响应手指触摸事件;pickable为false不可以被拾取，即不响应手指触摸事件。
-- @param #number iLeftMargin   如果此值为nil，则后面参数也将**被忽略**。 额外扩展可响应的左边区域。可用于改善不易点击到的小按钮的体验。
-- @param #number iRightMargin  如果此值为nil，则后面参数**不会被忽略**。 额外扩展可响应的右边区域。
-- @param #number iTopMargin    如果此值为nil，则后面参数**不会被忽略**。 额外扩展可响应的上边区域。 
-- @param #number iBottomMargin  额外扩展可响应的下边区域。
-- 
-- 如下图，当widget的点击区域设置为```setPickable(true,45,57,38,32)```，则widget的可以响应触摸的区域即是红色的框所包含的部分。
-- 
-- ![](http://engine.by.com:8080/hosting/data/1458284436076_4815350201568651050.png)
WidgetBase.setPickable = function(self, pickable, iLeftMargin, iRightMargin, iTopMargin, iBottomMargin)
	self.m_pickable = pickable;

    if iLeftMargin then 
        drawing_set_pickable(self.m_drawingID,pickable and kTrue or kFalse, 
            iLeftMargin or 0, iRightMargin or 0, iTopMargin or 0, iBottomMargin or 0)
    else 
	    drawing_set_pickable(self.m_drawingID,pickable and kTrue or kFalse,0,0,0,0);
    end 
end

---
-- 判断此widget是否可响应手指触摸事件。详见: @{#WidgetBase.setPickable}。
--
-- @param self
-- @return #boolean 是否响应手指触摸事件。返回true表示可以响应手指触摸事件，返回false表示不能响应手指触摸事件。
WidgetBase.getPickable = function(self)
	return self.m_pickable;
end

---
-- 给此widget设置手指触摸事件的回调.
-- 
--  手指触摸widget的时候，会调用```func(obj, finger_action, x, y, drawing_id_first,drawing_id_current,event_time) ``` 详见：<a href="#008">**8.触摸机制回调函数的参数的意义。**</a>
-- @param self
-- @param obj 在回调时传给func的值。
-- @param #function func 触摸事件的回调函数。
--
WidgetBase.setEventTouch = function(self, obj, func)
	drawing_set_touchable(self.m_drawingID, 
		(func or self.m_registedDoubleClick) and kTrue or kFalse, 
		self, WidgetBase.touchEventHandler);

	self.m_eventCallbacks.touch.obj = obj;
	self.m_eventCallbacks.touch.func = func;
end

---
-- 给此widget设置手指拖拽事件的回调. 
-- 
-- 手指触摸widget的时候，会调用```func(obj, finger_action, x, y, drawing_id_first,drawing_id_current,event_time) ``` 详见：<a href="#008">**8.触摸机制回调函数的参数的意义。**</a>
-- 
-- @param self
-- @param obj 在回调时传给func的值。
-- @param #function func 拖拽事件的回调函数。
WidgetBase.setEventDrag = function(self, obj, func)
	drawing_set_dragable(self.m_drawingID, func and kTrue or kFalse, self, WidgetBase.onEventDrag);

	self.m_eventCallbacks.drag.obj = obj;
	self.m_eventCallbacks.drag.func = func;
end

---
-- 设置双击事件回调.
--
--如果在500毫秒以内，第一次[```kFingerDown```](core.constants.html#kFingerDown)时所记录的```drawing_id_first```与第二次[```kFingerDown```](core.constants.html#kFingerDown)所记录的```drawing_id_first```相同，
--
--则会调用```func(obj, finger_action, x, y, drawing_id_first,drawing_id_current,event_time) ```详见：<a href="#008">**8.触摸机制回调函数的参数的意义。**</a>
-- 
-- @param self
-- @param obj 在回调时传给func的值。
-- @param #function func 回调函数。
WidgetBase.setEventDoubleClick = function(self, obj, func)
	self.m_registedDoubleClick = func and true or false;

	self.m_eventCallbacks.doubleClick.obj = obj;
	self.m_eventCallbacks.doubleClick.func = func;

	drawing_set_touchable(self.m_drawingID,
		(self.m_eventCallbacks.touch.func or self.m_registedDoubleClick) and kTrue or kFalse, 
		self, self.touchEventHandler);
end

------------------------------------------pos and size----------------------------------------------

---
-- 设置本widget相对于父widget的对齐方式.
--
-- 本widget将根据对齐方式（默认为[```kAlignTopLeft```](core.constants.html#kAlignTopLeft)）和 @{#WidgetBase.setPos} 所设置的x,y，调整本widget的位置。详见：<a href="#006">**引擎的子节点与父节点九种对齐方式和其相对位置**</a>
-- 
-- @param self
-- @param #number align  取值：[```kAlignCenter```](core.constants.html#kAlignCenter)、[```kAlignTop```](core.constants.html#kAlignTop)、[```kAlignTopRight```](core.constants.html#kAlignTopRight)、
-- [```kAlignRight```](core.constants.html#kAlignRight)、[```kAlignBottomRight```](core.constants.html#kAlignBottomRight)、[```kAlignBottom```](core.constants.html#kAlignBottom)、
-- [```kAlignBottomLeft```](core.constants.html#kAlignBottomLeft)、[```kAlignLeft```](core.constants.html#kAlignLeft)、[```kAlignTopLeft```](core.constants.html#kAlignTopLeft)。详见：<a href="#006">**引擎的子节点与父节点九种对齐方式和其相对位置**</a>
-- 
WidgetBase.setAlign = function(self, align)
	self.m_align = align or kAlignTopLeft;
	self:revisePos();
end

---
-- 设置绘制对象widget的位置.
--
-- 根据设置的对齐属性（默认为[```kAlignTopLeft```](core.constants.html#kAlignTopLeft)），来设置其相对于父节点的位置。默认设置为(0,0)。详见：<a href="#006">**引擎的子节点与父节点九种对齐方式和其相对位置**</a>
--
-- @param self
-- @param #number x 相对于父widget的横坐标。
-- @param #number y 相对于父widget的纵坐标。
WidgetBase.setPos = function(self, x, y)
	self.m_alignX = x or self.m_alignX;
	self.m_alignY = y or self.m_alignY;
	
	if not (self.m_fillParentWidth and self.m_fillParentHeight) then
		self:revisePos();
	end
end

---
-- 返回widget的位置.
-- 
-- 返回通过@{#WidgetBase.setPos}设置的位置。但如果widget的x轴方向和y轴方向是填充父节点的，则返回0，0。
-- 
-- @param self
-- @return #number,#number 横坐标, 纵坐标。 
WidgetBase.getPos = function(self)
	local x = self.m_fillParentWidth and 0 or self.m_alignX;
	local y = self.m_fillParentHeight and 0 or self.m_alignY;

	return x,y;
end

---
-- 返回相对于父widget的**未经过对齐方式设置**（默认对齐方式为左上对齐）、但经过屏幕适配缩放的坐标.
-- 如果widget没有填充父节点，并且对齐方式是左上对齐，
-- 则此方法返回的x,y和@{#WidgetBase.setPos}设置的是一样的。
--
-- @param self
-- @return #number, #number 横坐标，纵坐标。
WidgetBase.getUnalignPos = function(self)
	return self.m_x/System.getLayoutScale(),
		self.m_y/System.getLayoutScale();
end

---
-- 返回此widget相对于屏幕左上角的坐标(未经屏幕适配缩放的).
--
-- @param self
-- @return #number,#number 相对于屏幕左上角的横坐标，相对于屏幕左上角的纵坐标。
WidgetBase.getAbsolutePos = function(self)
	return WidgetBase.convertPointToSurface(self,0,0);
end

---
-- 设置widget在屏幕上显示的大小.
--
-- 如果设置了widget填充父节点，则这里的size设置无效。
-- 
-- @param self
-- @param #number w 宽度。
-- @param #number h 高度。
WidgetBase.setSize = function(self, w, h) 
	self.m_width = w or self.m_width or 0;
	self.m_height = h or self.m_height or 0;

	if not (self.m_fillParentWidth and self.m_fillParentHeight) then
		self:reviseSize();
		self:revisePos();
	end
end


---
-- 设置widget是否填充父节点.
-- 
-- @param self
-- @param #boolean doFillParentWidth 横向是否填充父节点(与父节点同样宽度)。
-- @param #boolean doFillParentHeight 纵向是否填充父节点(与父节点同样高度)。
WidgetBase.setFillParent = function(self, doFillParentWidth, doFillParentHeight)
	self.m_fillParentWidth = doFillParentWidth;
	self.m_fillParentHeight = doFillParentHeight;
	
	self:reviseSize();
	self:revisePos();
end

---
-- 返回是否填充父节点。  详见:@{#WidgetBase.setFillParent}。
--
-- @param self
-- @return #boolean, #boolean 横向是否填充父节点(与父节点同样宽度)，纵向是否填充父节点(与父节点同样高度)。
WidgetBase.getFillParent = function(self)
	return self.m_fillParentWidth,self.m_fillParentHeight;
end


---
-- 设置是否填充父节点的部分区域.
-- 如果填充父节点的部分区域，则widget会占据父节点的除上下左右间距外的所有空间。
--
-- @param self
-- @param #boolean doFill 是否填充。
-- @param #number topLeftX 左边的边距。
-- @param #number topLeftY 上边的边距。
-- @param #number bottomRightX 右边的边距。
-- @param #number bottomRightY 下边的边距。
WidgetBase.setFillRegion = function(self, doFill, topLeftX, topLeftY, bottomRightX, bottomRightY)
	self.m_fillRegion = doFill;
	if self.m_fillRegion then
		self.m_fillRegionTopLeftX = topLeftX;
		self.m_fillRegionTopLeftY = topLeftY;
		self.m_fillRegionBottomRightX = bottomRightX;
		self.m_fillRegionBottomRightY = bottomRightY;
	end
	
	self:reviseSize();
	self:revisePos();
end

---
-- 返回是否填充了父节点的部分区域。
--
-- @param self
-- @return #boolean, #number, #number, #number, #number 是否填充父节点的部分区域, 左边的边距, 上边的边距, 右边的边距, 下边的边距
-- 详见@{#WidgetBase.setFillRegion}。
WidgetBase.getFillRegion = function(self)
	return self.m_fillRegion,self.m_fillRegionTopLeftX,self.m_fillRegionTopLeftY,
		self.m_fillRegionBottomRightX,self.m_fillRegionBottomRightY;
end

---
-- 获取widget的大小.
-- 如果未填充父节点，则直接返回@{#WidgetBase.setSize}设置的大小。
-- 如果填充了父节点，则返回经过计算后的大小。
--
-- @param self
-- @return #number, #number 宽度,高度。
WidgetBase.getSize = function(self)
	if not (self.m_fillParentWidth or self.m_fillParentHeight or self.m_fillRegion) then
		return self.m_width,self.m_height;
	end

	if self.m_fillRegion then
		local w,h;
		if self.m_parent then
			w,h = self.m_parent:getSize();
		else
			w,h = System.getScreenWidth()/System.getLayoutScale(),
				System.getScreenHeight()/System.getLayoutScale();
		end

		w = w - self.m_fillRegionTopLeftX - self.m_fillRegionBottomRightX;
		h = h - self.m_fillRegionTopLeftY - self.m_fillRegionBottomRightY;

		return w,h;
	end

	if self.m_fillParentWidth and self.m_fillParentHeight then
		if self.m_parent then
			return self.m_parent:getSize();
		else
			return System.getScreenWidth()/System.getLayoutScale(),
				System.getScreenHeight()/System.getLayoutScale();
		end
	end

	local w= self.m_width;
	local h = self.m_height;

	if self.m_fillParentWidth then
		if self.m_parent then
			w = self.m_parent:getSize();
		else
			w = System.getScreenWidth()/System.getLayoutScale();
		end
	end

	if self.m_fillParentHeight then
		if self.m_parent then
			local tw = nil; 
			tw, h = self.m_parent:getSize();
		else
			h = System.getScreenHeight()/System.getLayoutScale();
		end
	end

	return w,h;
end


------------------------------------------ visible ----------------------------------------------

---
-- 设置可见性.
-- 
-- 注：一个widget的可见性是由自己和父节点的可见性共同决定。
-- 
-- 如果一个widget设置为了不可见，那所有的子widget都将不再显示也不再响应触摸事件。
-- 但父widget设置为可见，子widget的可见性由其自己决定。
--
-- @param self
-- @param #boolean visible  visible为true，则widget在屏幕上可以看见，visible为false，则widget在屏幕上看不见。
WidgetBase.setVisible = function(self, visible)
	self.m_visible = visible and true or false;
    drawing_set_visible(self.m_drawingID,self.m_visible and kTrue or kFalse);
end

---
-- 返回此widget是否可见.
-- 
-- (详见：@{#WidgetBase.setVisible})
-- @param self
-- @return #boolean 若为true，则widget可见；否则，widget不可见。
WidgetBase.getVisible = function(self)
	return self.m_visible;
end

------------------------------------------ level ------------------------------------------------

---
-- 设置drawing的level.
-- level影响绘制次序，在同一级的所有widget里,level越大则越后被绘制，会显示在上面。 如果不设置，则默认值是0，则按添加先后顺序进行绘制。详见：<a href="#005">**5.引擎的渲染顺序。**</a>
--
-- @param self
-- @param #number level widget的level。
WidgetBase.setLevel = function(self, level)
	self.m_level = level or self.m_level;
    drawing_set_level(self.m_drawingID, level);
end

---
-- 返回通过@{#WidgetBase.setLevel}设置的widget的level.
--
-- @param self
-- @return #number  widget的level。
WidgetBase.getLevel = function(self)
	return self.m_level;
end

------------------------------------------ name ------------------------------------------------

---
-- 设置widget的名字.
-- 之后可通过此name从widget树中查找到此widget
-- 同一级中的widget可以同名，但查找时找到即止，顺序不确定。
--
-- @param self
-- @param #string name widget的名字。
WidgetBase.setName = function(self, name)
	self.m_name = name;
	drawing_set_name(self.m_drawingID,name);
end

---
-- 返回widget的名字。
--
-- @param self
-- @return #string widget的名字。
WidgetBase.getName = function(self)
	return self.m_name;
end

---
-- 返回widget的全名.
-- 全名为一个table，由从最顶层widget到此widget之间每一层widget的name组成。
-- 其中某一个或多个name有可能为nil。
-- 例如：{"hall_root", "center_view", "game_item", "enter_button"}。
--
-- @param self
-- @return #table  widget的全名。
WidgetBase.getFullName = function(self)
	return WidgetBase.getRelativeName(self,nil);
end

---
-- 返回自relativeRoot到当前widget之前每一层widget的name.
-- 查找relativeRoot到此widget之间每一层widget的name。其中某一个或多个name有可能为nil。类似 @{WidgetBase.getFullName}。
--
-- @param self
-- @param #WidgetBase relativeRoot 根据此节点可以查到到widget的节点。
-- @return #table 自relativeRoot到当前widget之前每一层widget的name。
WidgetBase.getRelativeName = function(self, relativeRoot)
	local ret = {};
	local drawing = self;
	while drawing and drawing ~= relativeRoot do 
		ret[#ret+1] = drawing:getName();
		drawing = drawing:getParent();
	end

	if drawing ~= relativeRoot then
		return nil;
	end

	if relativeRoot then
		ret[#ret+1] = relativeRoot:getName();
	end

	local nNames = #ret;
	for i=1,math.floor(nNames/2) do 
		ret[i],ret[nNames+1-i] = ret[nNames+1-i],ret[i];
	end

	return ret;
end

 
 
------------------------------------------ child ------------------------------------------------

---
-- 添加一个子节点.
--
-- @param self
-- @param #WidgetBase child  子节点对象。
WidgetBase.addChild = function(self, child)
	if not child then
		return
	end
	
	if child.m_parent then
		child.m_parent:removeChild(child);
	end
		
	local ret = child:setParent(self); 
	--local ret = drawing_set_parent(child.m_drawingID,self.m_drawingID);
	
	local index = #self.m_children+1;
	self.m_children[index] = child;
	self.m_rchildren[child] = index;
	--child.m_parent = self;

	--child:revisePos();

	return ret;
end

---
-- 从此widget内移除某个子节点.
--
-- @param self
-- @param #WidgetBase child 需要被移除的子节点。
-- @param #boolean doCleanup 是否需要对该child执行资源清除操作。
-- doCleanup为true，则会对child执行delete()操作，doCleanup为false则不会child执行delete()操作。
WidgetBase.removeChild = function(self, child, doCleanup)
	local ret = child:setParent();

	local index = self.m_rchildren[child];
	if not index then return false end
	
	self.m_rchildren[child] = nil;
	self.m_children[index] = nil;

	if doCleanup then
		delete(child);
        child = nil;
	end

	return ret == 0;
end

---
-- 移除当前widget的所有子节点.
-- 
-- @param self
-- @param #boolean doCleanup 是否对所有子节点执行delete()操作。
WidgetBase.removeAllChildren = function(self, doCleanup)
	doCleanup = (doCleanup == nil) or doCleanup; -- default is true

	local allChildren = {};
	for _,v in pairs(self.m_children) do 
        WidgetBase.removeChild(self,v);
        if doCleanup then
        	delete(v);
        else
        	allChildren[#allChildren+1] = v;
        end
    end
    self.m_children = {};
    self.m_rchildren  = {};

    if not doCleanup then
    	return allChildren;
    end
end

---
-- 获取此节点的父节点.
--
-- @param self
-- @return #WidgetBase 父节点对象。
-- @return #nil 如果没有父节点，则返回nil。
WidgetBase.getParent = function(self)
	return self.m_parent;
end

---
-- 获取所有子节点.
-- 
-- @param self
-- @return #list<#WidgetBase> 包含所有子节点对象的lua数组。
WidgetBase.getChildren = function(self)
	return self.m_children;
end

---
-- 将此widget绘制在屏幕上 。详见：<a href = "#004">widget的添加</a>.
-- 
-- 如果此widget已经是其他widget的子节点，将会先从父节点中移除。
--
-- @param self
WidgetBase.addToRoot = function(self)
    if g_at_root_node == nil then
        g_at_root_count = 0
        g_at_root_node = new(DrawingEmpty)
        g_at_root_node:setName('widget_root')
        g_at_root_node:setDebugName('DrawingEmpty')
        g_at_root_node:setSize(System.getScreenScaleWidth(), System.getScreenScaleHeight());
        g_at_root_node:setParent()
    end
    g_at_root_node:addChild(self)
end

---
-- 从直接子节点中，根据节点的名字，查找子节点(不会进行深层遍历).
--
-- @param self
-- @param #string name 节点的名字。
-- @return #WidgetBase 节点对象。 
-- @return #nil 如果没有查找到此节点，返回nil。
WidgetBase.getChildByName = function(self, name)
	for _,v in pairs(self.m_children) do 
		if v.m_name == name then
			return v;
		end
	end
end
---
-- 给此widget设置触摸链的回调. 
-- 
-- 手指触摸widget的时候，会调用```func(obj, finger_action, x, y, drawing_id,event_time) ``` 详见：[触摸链回调](http://engine.by.com:8080/hosting/data/1450949285685_83637802319454263.html)
-- 
-- @param self
-- @param obj 在回调时传给func的值。
-- @param #function func 触摸链的回调函数。
WidgetBase.setEventMsgChain = function(self, obj, func)
	drawing_set_msgchain(self.m_drawingID, func and kTrue or kFalse, obj, func);
end

------------------------------------------ point convert -------------------------------------------

---
-- 将**相对于此widget左上角**的坐标转换为**相对于屏幕左上角**的绝对坐标(此坐标是未经屏幕适配缩放的).
--
-- @param self
-- @param #number x 相对于此widget左上角的x坐标。
-- @param #number y 相对于此widget左上角的y坐标。
-- @return #number, #number  **相对于屏幕左上角**的横坐标，**相对于屏幕左上角**的纵坐标。(此坐标是未经屏幕适配缩放的)。
WidgetBase.convertPointToSurface = function(self, x, y)
	local newX = drawing_convert_x_to_surface(self.m_drawingID,x*System.getLayoutScale() or 0);
	local newY = drawing_convert_y_to_surface(self.m_drawingID,y*System.getLayoutScale() or 0);
	
	return newX/System.getLayoutScale(),newY/System.getLayoutScale();
end

---
-- 将**相对于屏幕的左上角**的坐标转换为**相对于此widget左上角**的的坐标.
--
-- @param self
-- @param #number x 相对于屏幕的左上角的x坐标(未经缩放的，与@{#WidgetBase.convertPointToSurface}的返回值类似)。
-- @param #number y 相对于屏幕的左上角的y坐标(未经缩放的，与@{#WidgetBase.convertPointToSurface}的返回值类似)。
-- @return #number,#number **相对于widget左上角**的横坐标，**相对于widget左上角**的纵坐标。
WidgetBase.convertSurfacePointToView = function(self, x, y)
	local newX = drawing_convert_x_to_surface(self.m_drawingID,0);
	local newY = drawing_convert_y_to_surface(self.m_drawingID,0);
	
	return x-newX/System.getLayoutScale(),y-newY/System.getLayoutScale();
end


----------------------------------set matrix--------------------------------------


---
-- 给widget设置一个矩阵，设置这个矩阵之后，所有的setpos以及prop设置的内容全部无效。
--
-- @param self
-- @param #number m00 自定义矩阵的[0,0]位置的值.
-- @param #number m01 自定义矩阵的[0,1]位置的值.
-- @param #number m02 自定义矩阵的[0,2]位置的值.
-- @param #number m03 自定义矩阵的[0,3]位置的值.
-- @param #number m10 自定义矩阵的[1,0]位置的值.
-- @param #number m11 自定义矩阵的[1,1]位置的值.
-- @param #number m12 自定义矩阵的[1,2]位置的值.
-- @param #number m13 自定义矩阵的[1,3]位置的值.
-- @param #number m20 自定义矩阵的[2,0]位置的值.
-- @param #number m21 自定义矩阵的[2,1]位置的值.
-- @param #number m22 自定义矩阵的[2,2]位置的值.
-- @param #number m23 自定义矩阵的[2,3]位置的值.
-- @param #number m30 自定义矩阵的[3,0]位置的值.
-- @param #number m31 自定义矩阵的[3,1]位置的值.
-- @param #number m32 自定义矩阵的[3,2]位置的值.
-- @param #number m33 自定义矩阵的[3,3]位置的值.
-- 
--@return #boolean 是否应用成功.true表示应用成功，否则表示应用失败.
WidgetBase.setForceMatrix = function (self, m00, m01, m02, m03,
                                             m10, m11, m12, m13,
                                             m20, m21, m22, m23,
                                             m30, m31, m32, m33)
  return drawing_set_force_matrix(self.m_drawingID,1,m00, m01, m02, m03,
													 m10, m11, m12, m13,
													 m20, m21, m22, m23,
													 m30, m31, m32, m33)==1
end


---
--给widget设置一个矩阵，这个矩阵是在其位置矩阵和prop矩阵之左。即在setpos，以及所有的prop之后对widget生效（注：在openGl里是左乘，矩阵从右往左依次生效）。详见：[sequence的影响]( http://engine.by.com:8080/hosting/data/1454382209947_1086948224922269666.html)
-- 
-- @param self
-- @param #number m00 自定义矩阵的[0,0]位置的值.
-- @param #number m01 自定义矩阵的[0,1]位置的值.
-- @param #number m02 自定义矩阵的[0,2]位置的值.
-- @param #number m03 自定义矩阵的[0,3]位置的值.
-- @param #number m10 自定义矩阵的[1,0]位置的值.
-- @param #number m11 自定义矩阵的[1,1]位置的值.
-- @param #number m12 自定义矩阵的[1,2]位置的值.
-- @param #number m13 自定义矩阵的[1,3]位置的值.
-- @param #number m20 自定义矩阵的[2,0]位置的值.
-- @param #number m21 自定义矩阵的[2,1]位置的值.
-- @param #number m22 自定义矩阵的[2,2]位置的值.
-- @param #number m23 自定义矩阵的[2,3]位置的值.
-- @param #number m30 自定义矩阵的[3,0]位置的值.
-- @param #number m31 自定义矩阵的[3,1]位置的值.
-- @param #number m32 自定义矩阵的[3,2]位置的值.
-- @param #number m33 自定义矩阵的[3,3]位置的值.
-- 
--@return #boolean 是否应用成功.true表示应用成功，否则表示应用失败.
WidgetBase.setPreMatrix =function (self, m00, m01, m02, m03,
                                          m10, m11, m12, m13,
                                          m20, m21, m22, m23,
                                          m30, m31, m32, m33)

   return drawing_set_pre_matrix(self.m_drawingID,1,m00, m01, m02, m03,
													 m10, m11, m12, m13,
													 m20, m21, m22, m23,
													 m30, m31, m32, m33)==1
end

---
--给widget设置一个矩阵，这个矩阵在其位置矩阵之右，prop矩阵之左。即在setpos之前，以及所有的prop之后生效（注：在openGl里是左乘，矩阵从右往左依次生效）。详见：[sequence的影响]( http://engine.by.com:8080/hosting/data/1454382209947_1086948224922269666.html)
--
-- @param self
-- @param #number m00 自定义矩阵的[0,0]位置的值.
-- @param #number m01 自定义矩阵的[0,1]位置的值.
-- @param #number m02 自定义矩阵的[0,2]位置的值.
-- @param #number m03 自定义矩阵的[0,3]位置的值.
-- @param #number m10 自定义矩阵的[1,0]位置的值.
-- @param #number m11 自定义矩阵的[1,1]位置的值.
-- @param #number m12 自定义矩阵的[1,2]位置的值.
-- @param #number m13 自定义矩阵的[1,3]位置的值.
-- @param #number m20 自定义矩阵的[2,0]位置的值.
-- @param #number m21 自定义矩阵的[2,1]位置的值.
-- @param #number m22 自定义矩阵的[2,2]位置的值.
-- @param #number m23 自定义矩阵的[2,3]位置的值.
-- @param #number m30 自定义矩阵的[3,0]位置的值.
-- @param #number m31 自定义矩阵的[3,1]位置的值.
-- @param #number m32 自定义矩阵的[3,2]位置的值.
-- @param #number m33 自定义矩阵的[3,3]位置的值.
-- 
--@return #boolean 是否应用成功.true表示应用成功，否则表示应用失败.
WidgetBase.setPostMatrix = function (self,m00, m01, m02, m03,
                                           m10, m11, m12, m13,
                                           m20, m21, m22, m23,
                                           m30, m31, m32, m33)

   return drawing_set_post_matrix(self.m_drawingID,1,m00, m01, m02, m03,
													 m10, m11, m12, m13,
													 m20, m21, m22, m23,
													 m30, m31, m32, m33)==1
end



--------------- private functions, don't use these functions in your code -----------------------

---
-- 设置此widget的父节点.
-- **注：该函数被标记为“private function”，不建议直接调用该函数。**
--
-- @param self
-- @param #WidgetBase parent 父节点对象。
--
-- @return #boolean 设置结果的返回值。成功返回true，不成功返回false。
WidgetBase.setParent = function(self,parent)
	local ret = drawing_set_parent(self.m_drawingID,parent and parent:getID() or 0);
	self.m_parent = parent;

	if self.m_fillParentHeight or self.m_fillParentWidth or self.m_fillRegion then
		self:reviseSize();
	end
	self:revisePos();
	return ret == 0;
end

---
-- 获取某个widget实例.
-- @return #Widget widget对象实例。
WidgetBase.getWidget = function(self)
    return Widget.get_by_id(self.m_drawingID)
end

---
-- 重新根据align,fillParent等调整此widget的位置.
-- **注：该函数被标记为“private function”，不建议直接调用该函数。**
--
-- @param self
WidgetBase.revisePos = function(self)
	if self.m_fillRegion then
		self.m_x = self.m_fillRegionTopLeftX *System.getLayoutScale();
		self.m_y = self.m_fillRegionTopLeftY *System.getLayoutScale();

		drawing_set_position(self.m_drawingID, self.m_x, self.m_y);
		return
	end

	local parentW,parentH;

	local parent = WidgetBase.getParent(self);
	if not parent then
		parentW = System.getScreenWidth();
		parentH = System.getScreenHeight();
	else
		parentW,parentH = WidgetBase.getRealSize(parent);
	end

	local x,y = WidgetBase.getPos(self);
	x,y = x*System.getLayoutScale(),y*System.getLayoutScale();
	local w,h = WidgetBase.getRealSize(self);

	if self.m_align == kAlignTopLeft 
		or self.m_align == kAlignLeft 
		or self.m_align == kAlignBottomLeft then

		x = x;
	elseif self.m_align == kAlignTopRight
		or self.m_align == kAlignRight
		or self.m_align == kAlignBottomRight then

		x = parentW - w - x;
	elseif self.m_align == kAlignTop 
		or self.m_align == kAlignCenter
		or self.m_align == kAlignBottom then

		x = (parentW - w)/2 + x;
	end

	if self.m_align == kAlignTopLeft 
		or self.m_align == kAlignTop 
		or self.m_align == kAlignTopRight then

		y = y;
	elseif self.m_align == kAlignBottomLeft
		or self.m_align == kAlignBottom
		or self.m_align == kAlignBottomRight then

		y = parentH - h - y;
	elseif self.m_align == kAlignLeft 
		or self.m_align == kAlignCenter
		or self.m_align == kAlignRight then
		
		y = (parentH - h)/2 + y;
	end

	drawing_set_position(self.m_drawingID, x, y);

	self.m_x = x;
	self.m_y = y;
end

---
-- 得到此widget显示在屏幕上的真实大小(经过屏幕适配缩放后的).
-- 
-- **注：该函数被标记为“private function”，不建议直接调用该函数。**
-- @param self
-- @return #number,#number widget显示在屏幕上的宽度，widget显示在屏幕上的高度。
WidgetBase.getRealSize = function(self)
	local w,h = WidgetBase.getSize(self);
	return w*System.getLayoutScale(),
		h*System.getLayoutScale();
end

---
-- 重新根据align,fillParent等调整此widget的大小.
-- **注：该函数被标记为“private function”，不建议直接调用该函数。**
--
-- @param self
WidgetBase.reviseSize = function(self)
	drawing_set_size(self.m_drawingID,WidgetBase.getRealSize(self));

	for _,v in pairs(self.m_children or {}) do 
		if v.m_fillParentHeight or v.m_fillParentWidth or v.m_fillRegion then
			v:reviseSize();
		end
		v:revisePos();
	end
end

---
-- 注册到c++底层的touch事件回调函数.
-- 
-- **注：该函数被标记为“private function”，不建议直接调用该函数。**
--
-- @param self
-- @param #number finger_action 手指事件 。取值：[```kFingerDown```](core.constants.html#kFingerDown)（手指下压事件）、[```kFingerMove```](core.constants.html#kFingerMove)（手指移动事件）、[```kFingerUp```](core.constants.html#kFingerUp)（手指抬起事件）、[```kFingerCancel```](core.constants.html#kFingerCancel)（特殊情况）。。
-- @param #number x 手指触摸的x坐标。
-- @param #number y 手指触摸的y坐标。
-- @param #number drawing_id_first 手指按下时选中的widget的id。
-- @param #number drawing_id_current 当前手指按下的widget的id。
-- @param #number event_time 当前事件的触发时间(单位：毫秒)。
WidgetBase.touchEventHandler = function(self, finger_action, x, y, drawing_id_first, drawing_id_current, event_time)
	 if not self.m_registedDoubleClick then 
		--continue the event routing or not 
        WidgetBase.onEventTouch(self,finger_action,x,y,drawing_id_first,drawing_id_current, event_time)
		return
	 end
	 
	 --Double click considered
	 if finger_action == kFingerDown then 
		--retain the down pos
		self.m_touching = true;

	    self.m_touchDownX = x;
	    self.m_touchDownY = y;
		
		--start timing the double click event
	    if not self.m_doubleClickAnim then 
            self.m_doubleClickAnim = new(AnimInt,kAnimNormal,0,1,500);
            self.m_doubleClickAnim:setEvent(self,self.onDoubleClickEnd);
            self.m_douleClickDelayTimes = 0;
        end
		--respond the touch event and test if continue the event routing or not
        
        WidgetBase.onEventTouch(self,finger_action,x,y,drawing_id_first,drawing_id_current, event_time)

	 else
	 	if not self.m_touching then
	 		return
	 	end

		-- retain the last pos
		self.m_lastTouchX = x;
	    self.m_lastTouchY = y;
		
		-- if move the touch pos ,then not double click
	    if math.abs(self.m_touchDownX - x) > 10 
            or math.abs(self.m_touchDownY - y) > 10 then
            delete(self.m_doubleClickAnim);
			self.m_doubleClickAnim = nil;
	    end
		
		--if not double click ,response the move event
	    if not self.m_doubleClickAnim then 
           WidgetBase.onEventTouch(self,finger_action,x,y,drawing_id_first,drawing_id_current, event_time)
	    end
	    
		--if not move ,then up or cancle
	    if finger_action ~= kFingerMove then
			-- retain the touch stuff
			self.m_touching = false;
			
	        self.m_lastTouchX = x;
            self.m_lastTouchY = y;
            self.m_lastDrawing_id_first = drawing_id_first;
            self.m_lastDrawing_id_current = drawing_id_current;
            self.m_lastTouchEventTime = event_time;
            
	        if self.m_doubleClickAnim then 
	            self.m_douleClickDelayTimes = self.m_douleClickDelayTimes + 1;
	            
				--test double or not
	            if self.m_douleClickDelayTimes > 1 then
	                if drawing_id_first == drawing_id_current then 
                        WidgetBase.onEventDoubleClick(self,finger_action,x,y,drawing_id_first,drawing_id_current, event_time);
                    end
                    self.m_douleClickDelayTimes = 0;
                    delete(self.m_doubleClickAnim);
                    self.m_doubleClickAnim = nil;
                end
           end
        end
	 end
end

---
-- 分发触摸事件(touch/drag/doubleClick).
-- **注：该函数被标记为“private function”，不建议直接调用该函数。**
--
-- @param self
-- @param #string eventType 取值：```'drag'```,```' touch'```, ```'doubleClick'```。
-- @param ... 传入的触摸相关的其他参数。
--
-- @return #boolean 是否已经处理此事件。返回true已经处理此事件，返回false则没有处理此事件。
WidgetBase.onEvent = function(self, eventType, ...)
	local eventCallback = self.m_eventCallbacks[eventType];
	if eventCallback and eventCallback.func then 
		return eventCallback.func(eventCallback.obj,...);
	else -- this else branch is only for "continue touch",for others the return value has no meanings;
		return true;
	end
end


---
-- 触发双击事件.
-- **注：该函数被标记为“private function”，不建议直接调用该函数。**
--
-- @param self
-- @param #number finger_action 手指事件 。取值：[```kFingerDown```](core.constants.html#kFingerDown)（手指下压事件）、[```kFingerMove```](core.constants.html#kFingerMove)（手指移动事件）、[```kFingerUp```](core.constants.html#kFingerUp)（手指抬起事件）、[```kFingerCancel```](core.constants.html#kFingerCancel)（特殊情况）。
-- @param #number x 未经屏适配缩放的屏幕x坐标。
-- @param #number y 未经屏适配缩放的屏幕y坐标。
-- @param #number drawing_id 手指按下时选中的widget的id。
-- @param #number event_time 当前事件的触发时间(单位：毫秒)。
WidgetBase.onEventDoubleClick = function(self, finger_action, x, y, drawing_id, event_time)
    WidgetBase.onEvent(self,"doubleClick",finger_action,x,y,drawing_id, event_time);
end

---
-- 一次点击事件后已经超过一定时间(500毫秒)没有下一次点击事件，本次不再触发双击事件.
-- **注：该函数被标记为“private function”，不建议直接调用该函数。**
--
-- @param self
WidgetBase.onDoubleClickEnd = function(self)
	delete(self.m_doubleClickAnim);
	self.m_doubleClickAnim = nil;
	--if not catch the double click ,then response a touch up event
	if self.m_douleClickDelayTimes > 0 then 
        WidgetBase.onEventTouch(self,kFingerUp,self.m_lastTouchX,self.m_lastTouchY,self.m_lastDrawing_id_first,self.m_lastDrawing_id_current, self.m_lastTouchEventTime);
	end
end


--- 
-- 收到引擎底层回传的drag事件.
-- **注：该函数被标记为“private function”，不建议直接调用该函数。**
--
-- @param self
-- @param #number finger_action 手指事件 。取值：[```kFingerDown```](core.constants.html#kFingerDown)（手指下压事件）、[```kFingerMove```](core.constants.html#kFingerMove)（手指移动事件）、[```kFingerUp```](core.constants.html#kFingerUp)（手指抬起事件）、[```kFingerCancel```](core.constants.html#kFingerCancel)（特殊情况）。
-- @param #number x 屏幕x绝对坐标。
-- @param #number y 屏幕y绝对坐标。
-- @param #number drawing_id_first 手指按下时选中的widget的id。
-- @param #number drawing_id_current 当前手指按下的widget的id。
-- @param #number event_time 当前事件的触发时间(单位：毫秒)。
WidgetBase.onEventDrag = function(self, finger_action, x, y, drawing_id_first, drawing_id_current, event_time)
	x = x / System.getLayoutScale();
	y = y / System.getLayoutScale();

    WidgetBase.onEvent(self,"drag",finger_action,x,y,drawing_id_first,drawing_id_current, event_time);
end

---
-- 触发touch事件.
-- **注：该函数被标记为“private function”，不建议直接调用该函数。**
--
-- @param self
-- @param #number finger_action 手指事件 。取值：[```kFingerDown```](core.constants.html#kFingerDown)（手指下压事件）、[```kFingerMove```](core.constants.html#kFingerMove)（手指移动事件）、[```kFingerUp```](core.constants.html#kFingerUp)（手指抬起事件）、[```kFingerCancel```](core.constants.html#kFingerCancel)（特殊情况）。
-- @param #number x 屏幕x绝对坐标。
-- @param #number y 屏幕y绝对坐标。
-- @param #number drawing_id_first 手指按下时选中的widget的id。
-- @param #number drawing_id_current 当前手指按下的widget的id。
-- @param #number event_time 当前事件的触发时间(单位：毫秒)。
WidgetBase.onEventTouch = function(self, finger_action, x, y, drawing_id_first, drawing_id_current, event_time)
	x = x / System.getLayoutScale();
	y = y / System.getLayoutScale();
	
    return WidgetBase.onEvent(self,"touch",finger_action,x,y,drawing_id_first,drawing_id_current, event_time);
end

WidgetBase.addAutoCleanup = function(self, widget)
    table.insert(self._autoCleanup, widget)
end

local function table_remove(tbl, vv)
    for i, v in ipairs(tbl) do
        if v == vv then
            table.remove(tbl, i)
            break
        end
    end
end

WidgetBase.removeAutoCleanup = function(self, widget)
    table_remove(self._autoCleanup, widget)
end

WidgetBase.animate = function(self, action, on_stop)
    local Anim = require('animation')
    local anim = Anim.Animator(action, Anim.updator(self:getWidget()))
    table.insert(self._animations, anim)
    anim.on_stop = function()
        table_remove(self._animations, anim)
        if on_stop then
            on_stop(self, anim)
        end
    end
    anim:start()
    return anim
end

WidgetBase.stopAllAnimations = function(self)
    local anims = self._animations
    self._animations = {}
    for _, anim in ipairs(anims) do
        anim:stop()
    end
end


---
-- 使用FBO自动缓冲自己以及子节点渲染的内容，内容不脏的清空下，只需要重新渲染FBO贴图本身.
--
-- 
-- @type FBONode
-- @extends #WidgetBase
FBONode = class(WidgetBase);

---
-- override @{core.drawing#WidgetBase.getWidgetClass}
-- @return #FBOWidget 返回FBOWidget。
FBONode.getWidgetClass = function(self)
    return FBOWidget
end


---
-- 在FBOWidget的基础上加上后处理特效列表的处理。 能正确处理三种不同程度的脏状态：.
--
-- 
-- @type EffectsNode
-- @extends #WidgetBase
EffectsNode = class(WidgetBase);

---
-- override @{core.drawing#WidgetBase.getWidgetClass}
-- @return #EffectsWidget 返回EffectsWidget。
EffectsNode.getWidgetClass = function(self)
    return EffectsWidget
end


---
-- lua中定制Widget.
--
-- 
-- @type LuaNode
-- @extends #WidgetBase
LuaNode = class(WidgetBase);

---
-- override @{core.drawing#WidgetBase.getWidgetClass}
-- @return #LuaWidget 返回LuaWidget。
LuaNode.getWidgetClass = function(self)
    return LuaWidget
end



---
-- 包含对绘制对象的旋转、平移、缩放、裁剪、透明度、颜色等的操作.
--
-- 
-- @type DrawingBase
-- @extends #WidgetBase
DrawingBase = class(WidgetBase);

---
-- override @{core.drawing#WidgetBase.getWidgetClass}
-- @return #nil 返回nil。
DrawingBase.getWidgetClass = function(self)
    return nil
end

---
--  构造函数.
DrawingBase.ctor = function(self)
	self.m_r = 255;
	self.m_g = 255;
	self.m_b = 255;
	self.m_alpha = 1.0;
	
	self.m_props = {};

	self.m_eventCallbacks = {
		touch = {};
		drag = {};
		doubleClick = {};
	};
end

---
-- 析构函数.
DrawingBase.dtor = function(self)
	for k,v in pairs(self.m_props) do 
		delete(v["prop"]);
		for _,anim in pairs(v["anim"]) do 
			delete(anim);
		end
	end
	self.m_props = {};
end

---
-- 添加一个动态属性.
--
-- **注：该函数被标记为“private function”，不建议直接调用该函数。**
--
-- @param self
-- @param #number sequence 属性添加位置。应用属性时按照sequence从小到大的顺序进行变化。
-- 对于一个widget来说，每个sequence上只能同时存在一个属性。
-- 如果想重复使用sequence，需要先把之前添加的移除掉(详见：@{#DrawingBase.removeProp})，否则会添加失败。
-- @param core.prop#PropBase propClass 需要添加的prop的类对象。例如：@{core.prop#PropColor}、@{core.prop#PropRotate}、@{core.prop#PropRotateSolid}、@{core.prop#PropScale }、@{core.prop#PropScaleSolid }、@{core.prop#PropTranslate }、@{core.prop#PropTranslateSolid }、@{core.prop#PropTransparency }。
-- @param #number center 中心点。取值：[```kNotCenter```](core.constants.html#kNotCenter)、[```kCenterDrawing```](core.constants.html#kCenterDrawing)、[```kCenterXY```](core.constants.html#kCenterXY)。详见：<a href="#00703">指定widget的中心点</a>
-- @param #number x 相对于widget左上角(详见：<a href="#0070301">widget的左上角</a> )的x轴偏移。
-- @param #number y 相对于widget左上角(详见：<a href="#0070301">widget的左上角</a> )的y轴偏移。
-- @param #number animType 取值：[```kAnimNormal```](core.constants.html#kAnimNormal)、[```kAnimRepeat```](core.constants.html#kAnimRepeat)、[```kAnimLoop```](core.constants.html#kAnimLoop)。详见：<a href="#00702">动态变化的方式</a>
-- @param #number duration 动画总持续时间(单位：毫秒)。
-- @param #number delay 开始前的延迟时间(单位：毫秒)。在调用完本函数以后，再过 delay 毫秒，才可以看到本属性应用后的效果。
-- @param ... 动画和属性需要的其他参数。
--
-- @return core.anim#AnimBase 一个或多个与此属性相关联的动画。
DrawingBase.addAnimProp = function(self, sequence, propClass, center, x, y, animType, duration, delay, ...)
	if not DrawingBase.checkAddProp(self,sequence) then 
		self:removeProp(sequence);
	end

	delay = delay or 0;

	local nAnimArgs = select("#",...);
	local nAnims = math.floor(nAnimArgs/2);

	local anims = {};

	for i=1,nAnims do 
		local startValue,endValue = select(i*2-1,...);
		anims[i] = DrawingBase.createAnim(self,animType,duration,delay,startValue,endValue);
	end

	if nAnims == 1 then
		local prop = new(propClass,anims[1],center,x,y);
		if DrawingBase.doAddProp(self,prop,sequence,anims[1]) then
			return anims[1];
		end
	elseif nAnims == 2 then
		local prop = new(propClass,anims[1],anims[2],center,x,y);
		if DrawingBase.doAddProp(self,prop,sequence,anims[1],anims[2]) then
			return anims[1],anims[2];
		end
	elseif nAnims == 3 then
		local prop = new(propClass,anims[1],anims[2],anims[3],center,x,y);
		if DrawingBase.doAddProp(self,prop,sequence,anims[1],anims[2],anims[3]) then
			return anims[1],anims[2],anims[3];
		end
	elseif nAnims == 4 then
		local prop = new(propClass,anims[1],anims[2],anims[3],anims[4],center,x,y);
		if DrawingBase.doAddProp(self,prop,sequence,anims[1],anims[2],anims[3],anims[4]) then
			return anims[1],anims[2],anims[3],anims[4];
		end
	else
		for _,v in pairs(anims) do 
			delete(v);
		end
		error("There is not such a prop that requests more than 4 anims");
	end
end

---
-- 添加一个静态的属性(直接应用最终效果，没有变化过程).
-- **注：该函数被标记为“private function”，不建议直接调用该函数。**
--
-- @param self
-- @param #number sequence 属性添加位置。应用属性时按照sequence从小到大的顺序进行变化。
-- 对于一个widget来说，每个sequence上只能同时存在一个属性。
-- 如果想重复使用sequence，需要先把之前添加的移除掉(详见：@{#DrawingBase.removeProp})，否则会添加失败。
-- 
-- @param core.prop#PropBase propClass 需要添加的prop的类对象。例如：@{core.prop#PropColor}、@{core.prop#PropRotate}等。
-- @param ... 所添加的prop类的其他参数。
-- 
-- @return #boolean 是否添加成功。返回true表示添加成功，false表示添加失败。
DrawingBase.addSolidProp = function(self, sequence, propClass, ...)
	if not DrawingBase.checkAddProp(self,sequence) then 
		return
	end
	
	local prop = new(propClass, ...);
	DrawingBase.doAddProp(self,prop,sequence)
end

---
-- 创建一个动画。详见：@{@prop.anim#AnimDouble}.
--
-- **注：该函数被标记为“private function”，不建议直接调用该函数。**
--
-- @param self
-- @param #number animType 取值：[```kAnimNormal```](core.constants.html#kAnimNormal)、[```kAnimRepeat```](core.constants.html#kAnimRepeat)、[```kAnimLoop```](core.constants.html#kAnimLoop)。详见：<a href="#00702">动态变化的方式</a>
-- @param #number duration 动画总持续时间(单位：毫秒)。
-- @param #number delay 开始前的延迟时间(单位：毫秒)。在调用完本函数以后，再过 delay 毫秒，才可以看到本属性应用后的效果。
-- @param #number startValue 初始值。
-- @param #number endValue 结束值。
--
-- @return core.anim#AnimDouble 返回一个动画。
DrawingBase.createAnim = function(self, animType, duration, delay, startValue, endValue)
	local anim;
	if startValue and endValue then
		anim = new(AnimDouble,animType,startValue,endValue,duration,delay);
		return anim;
	end
end

---
-- 检测某个sequence是否可以被使用.
-- **注：该函数被标记为“private function”，不建议直接调用该函数。**
--
-- @param self
-- @param #number sequence 属性添加位置。应用属性时按照sequence从小到大的顺序进行变化。
-- 对于一个widget来说，每个sequence上只能同时存在一个属性。
-- 如果想重复使用sequence，需要先把之前添加的移除掉(详见：@{#DrawingBase.removeProp})，否则会添加失败。
--
-- @return #boolean sequence是否被使用。返回true表示sequence可以被使用，返回false表示sequence不可以被使用。
DrawingBase.checkAddProp = function(self, sequence)
	if self.m_props[sequence] then
		return false;
	end
	return true;
end

---
-- 添加一个属性.
-- **注：该函数被标记为“private function”，不建议直接调用该函数。**
--
-- @param self
-- @param core.prop#PropBase prop 应用到widget上的属性。
-- @param #number sequence 应用属性时按照sequence从小到大的顺序进行变化。
-- 对于一个widget来说，每个sequence上只能同时存在一个属性。
-- 如果想重复使用sequence，需要先把之前添加的移除掉(详见：@{#DrawingBase.removeProp})，否则会添加失败。
-- @param ... 属性的其他参数。
--
-- @return #boolean 是否添加成功。返回true表示添加成功，false表示添加失败。
DrawingBase.doAddProp = function(self, prop, sequence, ...)
	local anims = {select(1,...)};
	if DrawingBase.addProp(self,prop,sequence) then 
		self.m_props[sequence] = {["prop"] = prop;["anim"] = anims};
		return true;
	else
		delete(prop);
		for _,v in pairs(anims) do 
			delete(v);
		end
		return false;
	end
end

------------------------------------------ props ----------------------------------------------

---
-- 添加一个属性 (详见：@{core.prop}).
--
-- @param self
-- @param core.prop#PropBase prop 应用到widget上的属性。
-- @param #number sequence 属性添加位置。详见：[sequence的影响]( http://engine.by.com:8080/hosting/data/1451465498787_8655701166692189097.html)。在应用属性时按照sequence从小到大的顺序进行变化。
-- 对于一个widget来说，每个sequence上只能同时存在一个属性。
-- 如果想重复使用sequence，需要先把之前添加的移除掉(详见：@{#DrawingBase.removeProp})，否则会添加失败。
DrawingBase.addProp = function(self, prop, sequence)
    local ret = drawing_prop_add(self.m_drawingID, prop:getID(), sequence);
	return ret == 0;
end

---
-- 从widget内移除一个属性(详见：@{core.prop}).
-- 如果成功移除，同时会对此属性相关资源进行清理。
--
-- @param self
-- @param #number sequence 属性添加位置。详见：[sequence的影响]( http://engine.by.com:8080/hosting/data/1451465498787_8655701166692189097.html)。应用属性时按照sequence从小到大的顺序进行变化。
-- 对于一个widget来说，每个sequence上只能同时存在一个属性。
-- 如果想重复使用sequence，需要先把之前添加的移除掉(@{#DrawingBase.removeProp})，否则会添加失败。
-- @return #boolean 是否移除成功，返回true则属性移除成功，返回false则属性移除失败。
DrawingBase.removeProp = function(self, sequence)
    if drawing_prop_remove(self.m_drawingID, sequence) ~= 0 then
    	return false;
    end

	if self.m_props[sequence] then
		delete(self.m_props[sequence]["prop"]);
		for _,v in pairs(self.m_props[sequence]["anim"]) do 
			delete(v);
		end
		self.m_props[sequence] = nil;
	end
	return true;
end

---
-- 通过属性Id来移除某个属性.
-- 如果成功移除，同时会对此属性相关资源进行清理。
--
-- @param self
-- @param #number propId 属性的id。详见：@{core.prop#PropBase}。
-- @return #boolean 是否移除成功，返回true则属性移除成功，返回false则属性移除失败。
DrawingBase.removePropByID = function(self, propId)
	if drawing_prop_remove_id(self.m_drawingID, propId) ~= 0 then
		return false;
	end

	for k,v in pairs(self.m_props) do 
		if v["prop"]:getID() == propId then
			delete(v["prop"]);
			for _,anim in pairs(v["anim"]) do 
				delete(anim);
			end
			self.m_props[k] = nil;
			break;
		end
	end
	
	return true;
end

---
-- 添加一个颜色变化的动态属性 (详见：@{core.prop#PropColor}).
-- 
-- 其中rStart到rEnd，gStart到gEnd，bStart到bEnd的变化满足线性变化的规律,参考<a href = "#011">线性变换规律。</a>
-- 
-- @param self
-- @param #number sequence 属性添加位置。详见：[sequence的影响]( http://engine.by.com:8080/hosting/data/1451465498787_8655701166692189097.html)。应用属性时按照sequence从小到大的顺序进行变化。
-- 对于一个widget来说，每个sequence上只能同时存在一个属性。
-- 如果想重复使用sequence，需要先把之前添加的移除掉(详见：@{#DrawingBase.removeProp})，否则会添加失败。
-- @param #number animType 取值：[```kAnimNormal```](core.constants.html#kAnimNormal)、[```kAnimRepeat```](core.constants.html#kAnimRepeat)、[```kAnimLoop```](core.constants.html#kAnimLoop)。详见：<a href="#00702">动态变化的方式</a>
-- @param #number duration 动画总持续时间(单位：毫秒)。
-- @param #number delay 开始前的延迟时间(单位：毫秒)。在调用完本函数以后，再过 delay 毫秒，才可以看到本属性应用后的效果。
-- @param #number rStart 开始时RGB颜色中的R分量的值。取值范围：[0,1]。
-- @param #number rEnd 结束时RGB颜色中的R分量的值。取值范围：[0,1]。
-- @param #number gStart 开始时RGB颜色中的G分量的值。取值范围：[0,1]。
-- @param #number gEnd  结束时RGB颜色中的G分量的值。取值范围：[0,1]。
-- @param #number bStart 开始时RGB颜色中的B分量的值。取值范围：[0,1]。
-- @param #number bEnd 结束时RGB颜色中的B分量的值。取值范围：[0,1]。
--
-- @return core.anim#AnimBase,core.anim#AnimBase,core.anim#AnimBase 返回与此属性相关联的动画。
DrawingBase.addPropColor = function(self, sequence, animType, duration, delay, rStart, rEnd, gStart, gEnd, bStart, bEnd)
	return DrawingBase.addAnimProp(self,sequence,PropColor,nil,nil,nil,animType,duration,delay,rStart,rEnd,gStart,gEnd,bStart,bEnd);
end

---
-- 添加一个动态透明度变化的属性 (详见：@{core.prop#PropTransparency}).
-- 
-- 其中startValue到endValue的变化满足线性变化的规律,参考<a href = "#011">线性变换规律。</a>
-- 
-- @param self
-- @param #number sequence 属性添加位置。详见：[sequence的影响]( http://engine.by.com:8080/hosting/data/1451465498787_8655701166692189097.html)。应用属性时按照sequence从小到大的顺序进行变化。
-- 对于一个widget来说，每个sequence上只能同时存在一个属性。
-- 如果想重复使用sequence，需要先把之前添加的移除掉(详见：@{#DrawingBase.removeProp})，否则会添加失败。
-- @param #number animType 取值：[```kAnimNormal```](core.constants.html#kAnimNormal)、[```kAnimRepeat```](core.constants.html#kAnimRepeat)、[```kAnimLoop```](core.constants.html#kAnimLoop)。详见：<a href="#00702">动态变化的方式</a>
-- @param #number duration 动画总持续时间(单位：毫秒)。
-- @param #number delay 开始前的延迟时间(单位：毫秒)。在调用完本函数以后，再过 delay 毫秒，才可以看到本属性应用后的效果。
-- @param #number startValue 开始的透明度。取值范围：[0.0,1.0]。取值为0表示透明，取值为1表示不透明，取值为0.5为半透明。
-- @param #number endValue 结束时的透明度。取值范围：[0.0,1.0]。取值为0表示透明，取值为1表示不透明，取值为0.5为半透明。
--
-- @return core.anim#AnimBase 返回与此属性相关联的动画。
DrawingBase.addPropTransparency = function(self, sequence, animType, duration, delay, startValue, endValue)
	return DrawingBase.addAnimProp(self,sequence,PropTransparency,nil,nil,nil,animType,duration,delay,startValue,endValue);
end


---
-- 添加一个位移动画.
--
-- 其中startX到endX,startY到endY的变化满足线性变化的规律,参考<a href = "#011">线性变换规律。</a>
--
-- @param self
-- @param #number sequence 属性添加位置。详见：[sequence的影响]( http://engine.by.com:8080/hosting/data/1451465498787_8655701166692189097.html)。应用属性时按照sequence从小到大的顺序进行变化。
-- 对于一个widget来说，每个sequence上只能同时存在一个属性。
-- 如果想重复使用sequence，需要先把之前添加的移除掉(详见：@{#DrawingBase.removeProp})，否则会添加失败。
-- @param #number animType 取值：[```kAnimNormal```](core.constants.html#kAnimNormal)、[```kAnimRepeat```](core.constants.html#kAnimRepeat)、[```kAnimLoop```](core.constants.html#kAnimLoop)。详见：<a href="#00702">动态变化的方式</a>
-- @param #number duration 动画总持续时间(单位：毫秒)。
-- @param #number delay 开始前的延迟时间(单位：毫秒)。在调用完本函数以后，再过 delay 毫秒，才可以看到本属性应用后的效果。
-- @param #number startX 初始x坐标。相对于widget当前位置的左上角(详见：<a href="#0070301">widget的左上角</a> )的x轴方向上的偏移。
-- @param #number startY 初始y坐标。相对于widget当前位置的左上角(详见：<a href="#0070301">widget的左上角</a> )y轴方向上的偏移。
-- @param #number endX 结束时的x坐标。相对于widget当前位置的的左上角(详见：<a href="#0070301">widget的左上角</a> )x轴方向上的偏移。
-- @param #number endY 结束时的y坐标。相对于widget当前位置的左上角(详见：<a href="#0070301">widget的左上角</a> )y轴方向上的偏移。
--
-- @return core.anim#AnimBase, core.anim#AnimBase 返回与此属性相关联的动画。
DrawingBase.addPropTranslate = function(self, sequence, animType, duration, delay, startX, endX, startY, endY)
	local layoutScale = System.getLayoutScale();
	startX = startX and startX * layoutScale or startX;
	endX = endX and endX * layoutScale or endX;
	startY = startY and startY * layoutScale or startY;
	endY = endY and endY * layoutScale or endY;
	return DrawingBase.addAnimProp(self,sequence,PropTranslate,nil,nil,nil,animType,duration,delay,startX,endX,startY,endY);
end


---
-- 添加一个旋转动画.
-- 
-- drawing 会根据指定的中心点来顺时针旋转。其中startValue到endValue的变化满足线性变化的规律,参考<a href = "#011">线性变换规律。</a>
-- 
-- 
-- @param self
-- @param #number sequence 属性添加位置。详见：[sequence的影响]( http://engine.by.com:8080/hosting/data/1451465498787_8655701166692189097.html)。应用属性时按照sequence从小到大的顺序进行变化。
-- 对于一个widget来说，每个sequence上只能同时存在一个属性。
-- 如果想重复使用sequence，需要先把之前添加的移除掉(详见：@{#DrawingBase.removeProp})，否则会添加失败。
-- @param #number animType 取值：[```kAnimNormal```](core.constants.html#kAnimNormal)、[```kAnimRepeat```](core.constants.html#kAnimRepeat)、[```kAnimLoop```](core.constants.html#kAnimLoop)。详见：<a href="#00702">动态变化的方式</a>
-- @param #number duration 动画总持续时间(单位：毫秒)。
-- @param #number delay 开始前的延迟时间(单位：毫秒)。在调用完本函数以后，再过 delay 毫秒，才可以看到本属性应用后的效果。
-- @param #number startValue 开始的角度(单位：度)。取值(-∞， +∞)。
-- @param #number endValue 结束时的角度(单位：度)。取值(-∞， +∞)。
-- @param #number center 选取中心点。取值：[```kNotCenter```](core.constants.html#kNotCenter)（取此值时，不需要传入x,y的值）、[```kCenterDrawing```](core.constants.html#kCenterDrawing)（取此值时，不需要传入x,y的值）、[```kCenterXY```](core.constants.html#kCenterXY)（取此值时，要传入x,y的值，默认为0，0）。详见：<a href="#00703">指定widget的中心点</a>
-- @param #number x 相对于widget左上角(详见：<a href="#0070301">widget的左上角</a> )的x轴偏移。只有center的取值为[```kCenterXY```](core.constants.html#kCenterXY)的时候才有效。默认值为0。
-- @param #number y 相对于widget左上角(详见：<a href="#0070301">widget的左上角</a> )的y轴偏移。只有center的取值为[```kCenterXY```](core.constants.html#kCenterXY)的时候才有效。默认值为0。
-- 
-- @return core.anim#AnimBase 返回与此属性相关联的动画。
DrawingBase.addPropRotate = function(self, sequence, animType, duration, delay, startValue, endValue, center, x, y)
	local layoutScale = System.getLayoutScale();
	x = x and x * layoutScale or x;
	y = y and y * layoutScale or y;
	return DrawingBase.addAnimProp(self,sequence,PropRotate,center, x, y,animType,duration,delay,startValue,endValue);
end


---
-- 添加一个缩放动画.
-- 
-- widget 会根据指定的中心点来缩放。其中startX到endX,startY到endY的变化满足线性变化的规律,参考<a href = "#011">线性变换规律。</a>
-- 
-- @param self
-- @param #number sequence 属性添加位置。详见：[sequence的影响]( http://engine.by.com:8080/hosting/data/1451465498787_8655701166692189097.html)。应用属性时按照sequence从小到大的顺序进行变化。
-- 对于一个widget来说，每个sequence上只能同时存在一个属性。
-- 如果想重复使用sequence，需要先把之前添加的移除掉(详见：@{#DrawingBase.removeProp})，否则会添加失败。
-- @param #number animType 取值：[```kAnimNormal```](core.constants.html#kAnimNormal)、[```kAnimRepeat```](core.constants.html#kAnimRepeat)、[```kAnimLoop```](core.constants.html#kAnimLoop)。详见：<a href="#00702">动态变化的方式</a>
-- @param #number duration 动画总持续时间(单位：毫秒)。
-- @param #number delay 开始前的延迟时间(单位：毫秒)。在调用完本函数以后，再过 delay 毫秒，才可以看到本属性应用后的效果。
-- @param #number startX 开始时的x向初始缩放比例。 1.0为widget原始的大小。该值越大，则看到的widget越大。
-- @param #number endX 结束时的x向最终缩放比例。1.0为widget原始的大小。该值越大，则看到的widget越大。
-- @param #number startY 开始时的y向初始缩放比例。1.0为widget原始的大小。该值越大，则看到的widget越大。
-- @param #number endY 结束时的y向最终缩放比例。1.0为widget原始的大小。该值越大，则看到的widget越大。
-- @param #number center 选取中心点。取值：[```kNotCenter```](core.constants.html#kNotCenter)（取此值时，不需要传入x,y的值）、[```kCenterDrawing```](core.constants.html#kCenterDrawing)（取此值时，不需要传入x,y的值）、[```kCenterXY```](core.constants.html#kCenterXY)（取此值时，需要传入x,y的值，默认为0，0）。详见：<a href="#00703">指定widget的中心点</a>
-- @param #number x 相对于widget左上角(详见：<a href="#0070301">widget的左上角</a> )的x轴偏移。只有center的取值为[```kCenterXY```](core.constants.html#kCenterXY)的时候才有效。默认值为0。
-- @param #number y 相对于widget左上角(详见：<a href="#0070301">widget的左上角</a> )的y轴偏移。只有center的取值为[```kCenterXY```](core.constants.html#kCenterXY)的时候才有效。默认值为0。
--
-- @return core.anim#AnimBase,core.anim#AnimBase 返回与此属性相关联的动画。
DrawingBase.addPropScale = function(self, sequence, animType, duration, delay, startX, endX, startY, endY, center, x, y)
	local layoutScale = System.getLayoutScale();
	x = x and x * layoutScale or x;
	y = y and y * layoutScale or y;
	return DrawingBase.addAnimProp(self,sequence,PropScale,center, x, y,animType,duration,delay,startX,endX,startY,endY);
end



---
-- 添加一个静态位移属性,直接一次达到位置，没有移动的过程.
--
-- @param self
-- @param #number sequence 属性添加位置。详见：[sequence的影响]( http://engine.by.com:8080/hosting/data/1451465498787_8655701166692189097.html)。应用属性时按照sequence从小到大的顺序进行变化。
-- 对于一个widget来说，每个sequence上只能同时存在一个属性。
-- 如果想重复使用sequence，需要先把之前添加的移除掉(详见：@{#DrawingBase.removeProp})，否则会添加失败。
-- @param #number x 相对于widget当前位置的左上角(详见：<a href="#0070301">widget的左上角</a> )的x轴的偏移。
-- @param #number y 相对于widget当前位置的左上角(详见：<a href="#0070301">widget的左上角</a> )的y轴的偏移。
-- 
DrawingBase.addPropTranslateSolid = function(self, sequence, x, y)
	local layoutScale = System.getLayoutScale();
	x = x and x * layoutScale or x;
	y = y and y * layoutScale or y;
	DrawingBase.addSolidProp(self,sequence,PropTranslateSolid,x,y);
end

---
-- 添加一个静态旋转属性,没有旋转的过程.
--
-- widget 会根据指定的中心点来顺时针旋转。
-- @param self
-- @param #number sequence 属性添加位置。详见：[sequence的影响]( http://engine.by.com:8080/hosting/data/1451465498787_8655701166692189097.html)。应用属性时按照sequence从小到大的顺序进行变化。
-- 对于一个widget来说，每个sequence上只能同时存在一个属性。
-- 如果想重复使用sequence，需要先把之前添加的移除掉(详见：@{#DrawingBase.removeProp})，否则会添加失败。
-- @param #number angle360 旋转的角度。单位：度。
-- @param #number center 选取中心点。取值：[```kNotCenter```](core.constants.html#kNotCenter)（取此值时，不需要传入x,y的值）。、[```kCenterDrawing```](core.constants.html#kCenterDrawing)（取此值时，不需要传入x,y的值）、[```kCenterXY```](core.constants.html#kCenterXY)（取此值时，需要传入x,y的值，默认为0，0）。详见：<a href="#00703">指定widget的中心点</a>
-- @param #number x 相对于widget左上角(详见：<a href="#0070301">widget的左上角</a> )的x轴偏移。只有center的取值为[```kCenterXY```](core.constants.html#kCenterXY)的时候才有效。默认值为0。
-- @param #number y 相对于widget左上角(详见：<a href="#0070301">widget的左上角</a> )的y轴偏移。只有center的取值为[```kCenterXY```](core.constants.html#kCenterXY)的时候才有效。默认值为0。
--
DrawingBase.addPropRotateSolid = function(self, sequence, angle360, center, x, y)
	local layoutScale = System.getLayoutScale();
	x = x and x * layoutScale or x;
	y = y and y * layoutScale or y;
	DrawingBase.addSolidProp(self,sequence,PropRotateSolid,angle360,center,x,y);
end

---
-- 添加一个静态缩放属性.
--
-- widget 会根据指定的中心点来缩放。
-- @param self
-- @param #number sequence 属性添加位置。详见：[sequence的影响]( http://engine.by.com:8080/hosting/data/1451465498787_8655701166692189097.html)。应用属性时按照sequence从小到大的顺序进行变化。
-- 对于一个widget来说，每个sequence上只能同时存在一个属性。
-- 如果想重复使用sequence，需要先把之前添加的移除掉(详见：@{#DrawingBase.removeProp})，否则会添加失败。
-- @param #number scaleX x轴的缩放比例。1.0为widget原始的大小。该值越大，看到的widget越大。
-- @param #number scaleY y轴的缩放比例。1.0为widget原始的大小。该值越大，看到的widget越大。
-- @param #number center 选取中心点。取值：[```kNotCenter```](core.constants.html#kNotCenter)（取此值时，不需要传入x,y的值）、[```kCenterDrawing```](core.constants.html#kCenterDrawing)（取此值时，不需要传入x,y的值）、[```kCenterXY```](core.constants.html#kCenterXY)（取此值时，需要传入x,y的值，默认为0，0）。详见：<a href="#00703">指定widget的中心点</a>
-- @param #number x 相对于widget左上角(详见：<a href="#0070301">widget的左上角</a> )的x轴偏移。只有center的取值为[```kCenterXY```](core.constants.html#kCenterXY)的时候才有效。默认值为0。
-- @param #number y 相对于widget左上角(详见：<a href="#0070301">widget的左上角</a> )的y轴偏移。只有center的取值为[```kCenterXY```](core.constants.html#kCenterXY)的时候才有效。默认值为0。
--
DrawingBase.addPropScaleSolid = function(self, sequence, scaleX, scaleY, center, x, y)
	local layoutScale = System.getLayoutScale();
	x = x and x * layoutScale or x;
	y = y and y * layoutScale or y;
	DrawingBase.addSolidProp(self,sequence,PropScaleSolid,scaleX, scaleY,center,x,y);
end

------------------------------------------color ----------------------------------------------

---
-- 设置颜色.
-- 可以给任何widget设置一个RGB格式的颜色。如果未设置，默认为r = 255,g= 255,b= 255
-- 如果widget是个图片，则在图片上增加了一个颜色的叠加效果。
--
-- @param self
-- @param #number r RGB颜色中的R分量,取值范围：[0,255]。
-- @param #number g RGB颜色中的G分量,取值范围：[0,255]。
-- @param #number b RGB颜色中的B分量,取值范围：[0,255]。
DrawingBase.setColor = function(self, r, g, b)
	self.m_r = r or self.m_r;
	self.m_g = g or self.m_g;
	self.m_b = b or self.m_b;

	drawing_set_color(self.m_drawingID, self.m_r, self.m_g, self.m_b);
end

---
-- 返回通过@{#DrawingBase.setColor}设置的RGB格式的颜色.
--
-- @param self
-- @return #number, #number, #number RGB中的R分量,RGB中的G分量,RGB中的B分量。
DrawingBase.getColor = function(self)
	return self.m_r, self.m_g, self.m_b;
end


---
-- 设置drawing的透明度.
--
-- @param self
-- @param #number val 透明度,取值范围:[0,1]。0表示透明，1表示不透明，0.5表示半透明。
DrawingBase.setTransparency = function(self, val)
	self.m_alpha = val or self.m_alpha;
	local enable = (val>=0) and kTrue or kFalse;
	
	drawing_set_transparency(self.m_drawingID, enable, self.m_alpha);
end

---
-- 返回透明度.
-- 
-- @param self
-- @return #number 返回通过@{#DrawingBase.setTransparency}设置的值。
DrawingBase.getTransparency = function(self)
	return self.m_alpha;
end

------------------------------------------ clip ------------------------------------------------

---
-- 对widget进行剪裁.
-- 
-- 调用该函数以后，此widget只会显示相对于此widget的父widget左上角坐标为x,y，宽高为w,h的矩形区域和此widget的重叠的区域，该widget的子widget也只会显示在该矩形区域的部分。
-- 
-- 如下图所示：假设widget1为widget2的父节点，如果此时调用函数```setClip(60,30,w,h)```，那么灰色框所包含的区域clipArea即为其裁剪区域，widget2和widget2的子节点只会clipArea和widget2重叠的区域。
-- 
-- ![](http://engine.by.com:8080/hosting/data/1458284236976_2351027668795015711.png)
-- 
-- 注：
--  
-- * 该函数仅为兼容老程序而存在，并将会在未来版本删除。需要裁剪，请使用 @{#DrawingBase.setClip2} 。
-- * 若x,y,w,h中有一个小于0，则取消裁剪。
--
-- @param self
-- @param #number x 矩形裁剪区域相对于父widget左上角x轴坐标。
-- @param #number y 矩形裁剪区域相对于父widget左上角y轴坐标，。
-- @param #number w 矩形裁剪区域的宽。
-- @param #number h 矩形裁剪区域的高。
DrawingBase.setClip = function(self, x, y, w, h)
    local layoutScale = System.getLayoutScale();
    _drawing_set_clip_rect_parent_based(self.m_drawingID, x*layoutScale,y*layoutScale,w*layoutScale,h*layoutScale);
end



---
-- 对widget进行剪裁.
-- 
-- 启用裁剪以后，该widget只会显示相对于此widget左上角坐标为x,y，宽高为w,h的矩形区域，子widget也只会显示在该矩形区域的部分。
-- 
-- 如下图所示，如果此时调用函数```setClip(60,52,230,95)```，那么灰色框所包含的区域clipArea即为其裁剪区域，那么widget和widget的子节点只会显示clipArea所包含的区域。
-- 
-- ![](http://engine.by.com:8080/hosting/data/1458284302958_4700753848719222341.png)
-- 
-- @param self
-- @param #boolean enable enable为true，则启用裁减；enable为false，不启用裁减。
-- @param #number x 矩形裁剪区域相对于此widget左上角x轴坐标。
-- @param #number y 矩形裁剪区域相对于此widget左上角y轴坐标。
-- @param #number w 矩形裁剪区域的宽。
-- @param #number h 矩形裁剪区域的高。
DrawingBase.setClip2 = function(self, enable, x, y, w, h)
    local layoutScale = System.getLayoutScale();
    drawing_set_clip_rect(self.m_drawingID, enable and 1 or 0, 
        x*layoutScale,y*layoutScale,w*layoutScale,h*layoutScale);
end

----------------------------------------------------------------------------------------------
-----------------------------------[CLASS] Drawing Image--------------------------------------
----------------------------------------------------------------------------------------------

---
-- 有图片显示的widget，图片、按钮都是此类的子类.
--
-- 一个DrawingImage可以有多个位图资源，通过@{#DrawingImage.setImageIndex}来设置当前所显示的位图。
-- @type DrawingImage
-- @extends #DrawingBase
DrawingImage = class(DrawingBase);

---
-- 构造函数.
-- 
-- leftWidth,rightWidth,topWidth,bottomWidth四个参数，其中任何一个不是nil，则该图会被认为是九宫格图，其余是nil的参数，会被认为是0。如果是非九宫格图，这4个参数必须都传nil。详见：<a href = "#009">九宫格图片</a>
-- @param self
-- @param core.res#ResImage res 图片资源。
-- @param #number leftWidth 图片九宫拉伸的左边宽度。取值范围：[0,+∞） 。
-- @param #number rightWidth 图片九宫拉伸的右边宽度。取值范围：[0,+∞） 。
-- @param #number topWidth 图片九宫拉伸的顶部宽度。取值范围：[0,+∞） 。
-- @param #number bottomWidth 图片九宫拉伸的底部宽度。取值范围：[0,+∞） 。
DrawingImage.ctor = function(self, res, leftWidth, rightWidth, topWidth, bottomWidth)
    self.m_res = res;
    self.m_resID = res:getID();
    self.m_width = res:getWidth();
    self.m_height = res:getHeight();
    
    self.m_isGrid9 = (leftWidth or rightWidth or bottomWidth or topWidth) and true or false;
	
	local realWidth,realHeight = DrawingImage.getRealSize(self);
	local scale = System:getLayoutScale();
    leftWidth = leftWidth or 0;
    rightWidth = rightWidth or 0;
    bottomWidth = bottomWidth or 0;
    topWidth = topWidth or 0;
    local v_border = {leftWidth,rightWidth,topWidth,bottomWidth}
    if DrawingImage.NO_SCALE_9GRID ~= true then
        v_border[1] = v_border[1] * scale
        v_border[2] = v_border[2] * scale
        v_border[3] = v_border[3] * scale
        v_border[4] = v_border[4] * scale
    end
    drawing_create_image(0, self.m_drawingID, self.m_resID,
							self.m_x, self.m_y, realWidth, realHeight, 
							self.m_isGrid9  and kTrue or kFalse, leftWidth,rightWidth,topWidth,bottomWidth, 
							v_border[1],v_border[2],v_border[3],v_border[4],
							self.m_level);

	DrawingImage.setResRect(self,0,res);
  	DrawingImage.setResTrimAndRotate(self,0,res);
end


---
-- 根据索引设置当前位图资源（详见：@{core.res#ResImage}），将其绘制到屏幕上.
-- 一个DrawingImage可以添加多个位图资源，但同一时刻，只能显示一个位图资源。
-- 详见： @{#DrawingImage.addImage}。
--
-- @param self
-- @param #number idx 需要使用的位图资源的索引。
DrawingImage.setImageIndex = function(self, idx)
    drawing_set_image_index(self.m_drawingID, idx);
end

---
-- 添加一个位图资源（详见：@{core.res#ResImage}）.
-- 一个DrawingImage对象可以添加多个资源贴图，可以设置其中一个资源贴图作为当前值，来绘制到屏幕上。
-- 这种特性可用于支持帧动画。
--
-- @param self
-- @param core.res#ResImage res 位图资源。
-- @param #number index 位图资源。取值：非零正整数。可以根据索引来获取位图资源。
-- 
-- 注意：如果当前索引已经使用，新的位图资源则会覆盖之前的位图资源。
-- 
-- DrawingImage在创建时指定的位图资源的索引为0。
DrawingImage.addImage = function(self, res, index)
    drawing_set_image_add_image(self.m_drawingID, res:getID(), index);
    DrawingImage.setResRect(self,index,res);
    DrawingImage.setResTrimAndRotate(self,index,res);
end

---
-- 移除一个位图资源.
--
-- @param self
-- @param #number index 取值为非零正整数,位图资源的下标。
DrawingImage.removeImage = function(self, index)
    drawing_set_image_remove_image(self.m_drawingID, index);
end

---
-- 移除所有后续添加的位图资源。但初始化DrawingImage时指定的不会移除.
--
-- @param self
DrawingImage.removeAllImage = function(self)
    drawing_set_image_remove_all_images(self.m_drawingID);
end

---
-- 析构函数.
--
-- @param self
DrawingImage.dtor = function(self)
	--drawing_delete(self.m_drawingID);
end

---
-- 设置一个位图资源应该被用来显示的的部分。主要用在经过拼图的图片.
-- **注：该函数被标记为“private function”，不建议直接调用该函数。**
-- 
-- @param self
-- @param #number index 索引。取值为非零正整数。
-- @param core.res#ResImage res 图片资源。
DrawingImage.setResRect = function(self, index, res)
	if typeof(res,ResImage) then
		local subTexX,subTexY,subTexW,subTexH = res:getSubTextureCoord();													
		if subTexX and subTexY and subTexW and subTexH then 
			drawing_set_image_res_rect(self.m_drawingID,index,subTexX,subTexY,subTexW,subTexH);
		else
		    local width,height = res:getWidth(),res:getHeight();
		    drawing_set_image_res_rect(self.m_drawingID,index,0,0,width,height);
		end
	end
end

---
-- (设置一个位图资源应该被用来显示的的部分。主要用在经过拼图的图片.)
-- 是对DrawingImage.setResRect 的补充，为了支持拼图的Trim 和 Rotate 模式
-- **注：该函数被标记为“private function”，不建议直接调用该函数。**
-- 
-- @param self
-- @param core.res#ResImage res 图片资源。
DrawingImage.setResTrimAndRotate = function(self,index, res)
  if typeof(res,ResImage) then
    local _,_,subTexW,subTexH,subOffsetX,subOffsetY,subTexUtW,subTexUtH,subTexRotated = res:getSubTextureCoord();                         
    if subTexRotated ~= nil then
      drawing_set_rotated(self.m_drawingID,index,subTexRotated);
    end
    if subTexW and subTexH and subOffsetX and subOffsetY and subTexUtW and subTexUtH then
      if subTexRotated == true then
        drawing_set_trim_border(self.m_drawingID, index, subOffsetX, subOffsetY,
                subTexUtW - subTexH - subOffsetX,
                subTexUtH - subTexW - subOffsetY);
      else
        drawing_set_trim_border(self.m_drawingID, index, subOffsetX, subOffsetY,
                subTexUtW - subTexW - subOffsetX,
                subTexUtH - subTexH - subOffsetY);
      end
    end
  end
end

---
-- 设置某一个位图资源需要渲染的区域.
-- **注：该函数被标记为“private function”，不建议直接调用该函数。**
--
-- @param self
-- @param #number index 索引。取值为非零正整数。
-- @param #number x 相对于位图资源左上角(详见：<a href="#0070301">widget的左上角</a> )上的横坐标。
-- @param #number y 相对于位图资源左上角(详见：<a href="#0070301">widget的左上角</a> )上的纵坐标。
-- @param #number w 需要渲染的的宽度。
-- @param #number h 需要渲染的的高度。
DrawingImage.setResRectPlain = function(self, index, x, y, w, h)
	if x and y and w and h then 
		drawing_set_image_res_rect(self.m_drawingID,index,x,y,w,h);
	end
end

---------------------------------------other set----------------------------------------


---
--设置镜像，不要用shader，用这种方式渲染更快。
--
--@param self
--@param #boolean mirrorX mirrorX为true则横向镜像翻转，false表示横向不翻转.
--@param #boolean mirrorY mirrorY为true则纵向镜像翻转，false表示纵向不翻转.
--@return #boolean true或false.返回true表示应用成功，否则表示应用失败.
DrawingImage.setMirror = function(self,mirrorX,mirrorY)
   if type(mirrorX)~= "boolean" or type(mirrorY)~= "boolean" then
     error("ERROR type is not boolean");
   end
  
   return  drawing_set_mirror(self.m_drawingID,mirrorX==true and kTrue or kFalse,mirrorY==true and kTrue or kFalse)>0
end


---
-- 给widget设置一个shader，widget之后用这个shader来渲染。
-- 
-- @param self
-- @param #number shaderId 渲染的shader ID.
-- @return #boolean 是否应用成果.返回true表示应用成功，否则表示应用失败.
DrawingImage.setShader = function (self,shaderId)
   assert(false, 'invalid api')
   return drawing_set_shader(self.m_drawingID,shaderId)==1
end

----------------------------------------------------------------------------------------------
-----------------------------------[CLASS] Drawing Empty--------------------------------------
----------------------------------------------------------------------------------------------


---
-- 渲染结构树上一个空节点，不渲染什么内容.
--
-- @type DrawingEmpty
-- @extends #DrawingBase
DrawingEmpty = class(DrawingBase);

---
-- 构造函数.
DrawingEmpty.ctor = function(self)
	drawing_create_node(0,self.m_drawingID,self.m_level);
end

---
-- 析构函数.
DrawingEmpty.dtor = function(self)
	--drawing_delete(self.m_drawingID);
end



end
        

package.preload[ "core.drawing" ] = function( ... )
    return require('core/drawing')
end
            

package.preload[ "core/eventDispatcher" ] = function( ... )
-- evnetDispatcher.lua
-- Author: Vicent.Gong
-- Date: 2012-07-11
-- Last modification : 2013-05-29
-- Description: Implemented a evnet dispatcher to handle default event.

--------------------------------------------------------------------------------
-- 一个全局的事件分发的消息系统，为了支持不同模块或子模块之间的无耦合或弱耦合通信.
-- 
-- 对事件的发生感兴趣的可以注册这个事件的消息，此事件发生会进行消息派发，注册过此事件的会响应这个消息。
-- 
-- 概念介绍：
-- ---------------------------------------------------------------------
-- **1.事件类型**
-- 
-- * 预定义类型：系统已经定义好的，由系统分发的事件。详见：@{#Event}。
-- 
-- * 自定义类型：客户端自己定义的消息类型，客户端的不同模块分别负责分发和接收。
-- 
-- 
-- @module core.eventDispatcher
-- @return #nil 
-- @usage require("core/eventDispatcher")

require("core/object");
require("core/global");

---
-- 预定义事件.
-- 
-- @type Event
Event = {
	---
	-- 手指事件。详见：[`event_touch_raw`](core.systemEvent.html#event_touch_raw)。
    RawTouch    = 1,
    ---
    -- 收到native层的调用，用于原生代码和lua代码通信。详见：[`event_call`](core.systemevent.html#event_call)。
	Call    	= 2,
	---
	-- 键盘按下事件。
	KeyDown    	= 3,
	---
	-- 程序进入后台。(如跳转到别的程序，或按home键回到桌面。)
	Pause 		= 4,
	---
	-- 程序进入前台。(重新回到游戏。)
	Resume 		= 5,
    ---
    -- 暂未使用。
    Set         = 6,
    ---
    -- 暂未使用。
    Network     = 7,
    ---
    -- 按下返回键。
    Back        = 8,
    ---
    -- 系统定时器到达。
    Timeout     = 9,
    ---
    -- 结束标识。
    End         = 10,
};

---
-- 事件状态.
-- @type EventState
EventState = 
{
	---
	-- 事件将被移除
	RemoveMarked = 1,
};

local s_instance = nil

---
-- 用于派发和接收消息.
-- @type EventDispatcher
EventDispatcher = class();

---
-- 获取单例，@{#EventDispatcher}所包含的接口都要通过获取其相应的实例之后来调用.
--
-- @return #EventDispatcher 唯一实例。
EventDispatcher.getInstance = function()
	if not s_instance then 
		s_instance = new(EventDispatcher);
	end
	return s_instance;
end

---
-- 释放单例.
-- 请留意：如果调用过此方法，之后再使用getUserEvent来生成事件ID，生成的ID会和释放单例之前生成的出现重复。
EventDispatcher.releaseInstance = function()
	delete(s_instance);
	s_instance = nil;
end

---
-- 构造函数.
EventDispatcher.ctor = function(self)
	self.m_listener = {};
	self.m_tmpListener = {};
	self.m_userKey = Event.End;
end

---
-- 生成一个事件ID.
-- 在定义事件名时可以使用此方法来生成一个唯一的事件id。
-- 事件id是一个整型。
--
-- @paran self
-- @return #number ID 唯一的事件ID。
EventDispatcher.getUserEvent = function(self)
	self.m_userKey = self.m_userKey + 1;
	return self.m_userKey;
end

---
-- 注册消息.
-- 
-- 调用此方法后，当事件出现时，回调函数会得到调用。
-- 
-- **如果在事件处理函数里再调用此方法来注册其他事件，则会等到这次事件完全传播完成后才会生效。**
--
-- @param self
-- @param #number event 事件名 建议使用 @{#EventDispatcher.getUserEvent} 来生成。
-- @param obj 任何对象。在回收到事件通知时传回此对象。
-- @param #function func 事件的回调函数。传入参数为 (obj, ...) 其中...为分发时传入的其他参数。
EventDispatcher.register = function(self, event, obj, func)
	local arr;
	if self.m_dispatching then
		self.m_tmpListener[event] = self.m_tmpListener[event] or {};
		arr = self.m_tmpListener[event];
	else
		self.m_listener[event] = self.m_listener[event] or {};
		arr = self.m_listener[event];
	end
	
	arr[#arr+1] = {["obj"] = obj,["func"] = func,};
end

---
-- 清除注册事件.
-- 必须当obj和func都和注册事件时的相同时，才会取消注册。
-- 也就是说，可使用同一个函数与不同的obj配合注册多次。
-- 如：
--
--		local event = EventDispatcher.getInstance():getUserEvent()
--		local function eventResolver(obj,...)
--		
--		end
--		
--		local objA = {}
--		local objB = {}
--		EventDispatcher.getInstance():register(event, objA, eventResolver)
--		EventDispatcher.getInstance():register(event, objB, eventResolver)
--		EventDispatcher.getInstance():unregister(event, objA, eventResolver) -- 此步操作后，objB注册的事件依然有效
--
-- @param self
-- @param #number event 事件ID。
-- @param obj 注册事件时传入的obj。
-- @param #function func 注册事件时传入的回调函数。
EventDispatcher.unregister = function(self, event, obj, func)
	if not self.m_listener[event] then return end; 

	local arr = self.m_listener[event] or {};
	--for k,v in pairs(arr) do 
	for i=1,table.maxn(arr) do 
		local listerner = arr[i];
		if listerner then
			if (listerner["func"] == func) and (listerner["obj"] == obj) then 
				arr[i].mark = EventState.RemoveMarked;
				if not self.m_dispatching then
					arr[i] = nil;
				end

				--don't break so fast now,take care of the dump event listener
				--return
			end
		end
	end
end

---
-- 派发消息事件.
-- 
-- @param self
-- @param #number event 事件ID。
-- @param ... 其他需要携带的参数，这些参数会传给@{#EventDispatcher.register}所注册的事件的回调函数。
-- @return #boolean 如果有此事件的接收者，并且所有处理函数都返回了true，则dispatch方法返回true。可以用来标识是否有回调函数实际响应这个消息。
EventDispatcher.dispatch = function(self, event, ...)
	if not self.m_listener[event] then return end;

	self.m_dispatching = true;

	local ret = false;
	local listeners = self.m_listener[event] or {};
	--for _,v in pairs(listeners) do 
	for i=1,table.maxn(listeners) do 
		local listener = listeners[i]
		if listener then
			if listener["func"] and  listener["mark"] ~= EventState.RemoveMarked then 
				ret = ret or listener["func"](listener["obj"],...);
			end
		end
	end

	self.m_dispatching = false;

	EventDispatcher.cleanup(self);

	return ret;
end

---
-- 完成在“发送事件期间”注册的事件的添加操作，并移除在此期间被移除的事件.
-- **注：该函数被标记为“private function”，不建议直接调用该函数。**
--
-- @param self
EventDispatcher.cleanup = function(self)
	for event,listeners in pairs(self.m_tmpListener) do 
		self.m_listener[event] = self.m_listener[event] or {};
		local arr = self.m_listener[event];
		--for k,v in pairs(listeners) do 
		for i=1,table.maxn(listeners) do 
			local listener = listeners[i];
			if listener then
				arr[#arr+1] = listener;
			end
		end
	end

	self.m_tmpListener = {};

	for _,listeners in pairs(self.m_listener) do
		--for k,v in pairs(listeners) do 
		for i=1,table.maxn(listeners) do 
			local listener = listeners[i];
			if listener and (listener.mark == EventState.RemoveMarked or listener.func == nil) then 
				listeners[i] = nil;
			end
		end
	end
end

---
-- 析构函数
EventDispatcher.dtor = function(self)
	self.m_listener = nil;
end

end
        

package.preload[ "core.eventDispatcher" ] = function( ... )
    return require('core/eventDispatcher')
end
            

package.preload[ "core/gameString" ] = function( ... )
-- gameString.lua
-- Author: Vicent Gong
-- Date: 2012-09-30
-- Last modification : 2013-05-29
-- Description: provide basic wrapper for game string handler

--------------------------------------------------------------------------------
-- 用于文字国际化和一些编码转换.
--
-- @module core.gameString
-- @return #nil
-- @usage require("core.gameString")


require("core.object");
require("core.system")

---
-- @type GameString
GameString = class();

local s_platform = System.getPlatform();
local s_win32Code = "utf-8";

---
-- 设置win32环境下的文字编码.
-- 如果在win32下出现中文乱码，可尝试使用此来解决。
--
-- @param #string win32Code 编码格式。
GameString.setWin32Code = function(win32Code)
  s_win32Code = win32Code or s_win32Code;
end

---
-- 加载一个string文件.
-- string文件中写有游戏里需要用到的文字，所有文字全部都是全局变量，如：
--
--		login_btn_text = "登录"
--		title_money = "金币"
--
--
-- @param #string filename lua文件名。
-- @param #string lang 语言类型。如果lang为nil，在win32平台下，编码格式为```'gbk'```时，则会将语言指定为 ```zw```；
-- 否则，则会使用System.getLanguage()获得的语言。
--
-- 如传入`("text/string", "zh")`，则会加载`text/string_zh.lua`文件。
GameString.load = function(filename, lang)
  if not lang then
    if s_platform == kPlatformWin32 and s_win32Code == "gbk" then
      lang = "zw";
    else
      lang = System.getLanguage();
    end
  end

  local languageLuaFile = string.format("%s_%s",filename,lang);
  if pcall(require,languageLuaFile) == false then
    if pcall(require,filename) == false then
      error("load string file failed, not default string file exist");
    end
  end
end

---
-- 通过key得到文字字符串.
--
-- @param #string key  键值字符串。
GameString.get = function(key)
  local str= _G[key];
  return str;
end

---
-- 将字符串转换为utf8编码.
--
-- @param #string str 源字符串。
-- @param #string sourceCode 源字符串的编码格式。
-- @return #string 转换为UTF8编码的字符串。
GameString.convert2UTF8 = function(str, sourceCode)
  if not sourceCode then
    if s_platform == kPlatformWin32 then
      sourceCode = s_win32Code;
    else
      sourceCode = "utf-8";
    end
  end

  if sourceCode == "utf-8" then
    return str;
  else
    return string_encoding(sourceCode,"utf-8",str);
  end
end



GameString.convert2Platform = function(str, sourceCode)
  sourceCode = sourceCode or "utf-8";
  local platformCode = (s_platform == kPlatformWin32) 
              and s_win32Code or "utf-8";

  if sourceCode == platformCode then
    return str;
  else
    return string_encoding(sourceCode,platformCode,str);
  end
end

end
        

package.preload[ "core.gameString" ] = function( ... )
    return require('core/gameString')
end
            

package.preload[ "core/global" ] = function( ... )
-- global.lua
-- Author: Vicent Gong
-- Date: 2012-09-30
-- Last modification : 2013-05-30
-- Description: provide some global functions

--------------------------------------------------------------------------------
-- 一些常用的全局函数。
--
-- @module core.global
-- @return #nil
-- @usage require("core.global")


---
-- 完全等同于print_string.
-- 用于打印日志。
--
-- @param #string logStr 日志信息。
FwLog = function(logStr)
  print_string(logStr);
end

---
-- 深度拷贝.
-- 如果是table类型，则会深度拷贝，包括metatable也会被拷贝一份。
--
-- @param t 任意类型。
-- @return t的拷贝。
Copy = function(t)
  local lookup_table = {}

  local  function _copy(t)
    if type(t) ~= "table" then
      return t;
    elseif lookup_table[t] then
      return lookup_table[t];
    end

    local ret = {};
    lookup_table[t] = ret;
    for k,v in pairs(t) do
      ret[_copy(k)] =_copy(v);
    end

    local mt = getmetatable(t);
    setmetatable(ret,_copy(mt));
    return ret;
  end
  return _copy(t);
end

---
-- 将多个table合并为一个使用下标的形式的table.
-- 参数里的非table数据会被忽略。
-- 使用key-value形式的table的value也会被放入结果中，但顺序可能是不确定的。
--
-- **此方法只适合用来合并使用下标形式的table。**
--
-- 如：
--
-- MegerTables({1,2,3},nil,{name="peter",age=0},{{11,12},nil,"2008"})
-- 得到的结果是：{1,2,3,"peter",0,{11,12},"2008"} ，其中```'peter'```和0的顺序可能是不一定的。
--
-- 注意：最终结果里的{11,12}和传入参数里的{11,12}实际指向同一个对象.
--
-- 参见[core.global#CombineTables](#CombineTables)
--
-- @param ... 需要合并的tables。
-- @return #table 合并后的table。
MegerTables = function(...)
  local ret = {};
  local count = select("#",...);
  for i=1,count do
    local t = select(i,...);
    if type(t) == "table" then
      for _,v in pairs(t) do
        ret[#ret+1] = v;
      end
    end
  end
  return ret;
end


---
-- 将多个table合并为一个使用key-value的形式table，如果key值相同，会覆盖之前的数据.
-- 参数里的非table数据会被忽略。
--
-- **此方法只适合用来合并使用key-value形式的table。**
--
-- 如:
--
-- CombineTables({1,2,3},nil,{name="peter",age=0},{{11,12},nil,"2008"})
-- 得到的结果是：{{11,12},2,"2008",name="peter",age=0}。 因为1和{11,12}这两个数据的index都是1，所以后面的会覆盖前面的。
--
-- 参见[core.global#MegerTables](#MegerTables)
-- @param ... 需要合并的tables。
-- @return #table 合并后的table。
CombineTables = function(...)
  local ret = {};
  local count = select("#",...);
  for i=1,count do
    local t = select(i,...);
    if type(t) == "table" then
      for k,v in pairs(t) do
        ret[k] = v;
      end
    end
  end
  return ret;
end

---
-- 创建一个使用弱引用的table.
-- 弱引用：当某一个对象的所有引用都是弱引用时，该对象会被释放。
--
-- 例1：
--
--      t=CreateTable("v")
--      a={1,2,3}
--      t.key = a
--      a=nil
--      之后t.key会变为nil (当然，gc并不是实时的)
--
-- 例2:
--
--      t=CreateTable("k")
--      key={}
--      t[key]=123
--      key=nil
--      之后t会变为一个空table
--
-- @param #string weakOption 取值(```'k'/'v'/'kv'```)。
-- @return #table  使用弱引用的table。
CreateTable = function(weakOption)
  if not weakOption or (weakOption ~= "k" and weakOption ~= "v" and weakOption ~= "kv") then
    return {};
  end

  local ret = {};
  setmetatable(ret,{__mode = weakOption});
  return ret;
end


---
-- 计算两个array(使用下标形式的table)的差.
-- 也就是除去arry1中的value值和array2中的value值相同的数据，当arry1中有m个相同值的value与array2中的n个相同值的value，则arry2中有多少个，arry1就去除多少个，直到arry1中没有相同的value值。
-- 仅比较使用数字下标的值，key-value形式的会被忽略。
--
-- 例：
--
--      t1={2,3,4,5,6,5}
--      t2={1,3,5}
--      则SubTractArray(t1, t2)的结果是{2,4,6,5}
--
-- @param #table arr1 被减数。
-- @param #table arr2 减数。
-- @return #table arr1-arr2 的结果。
SubtractArray = function(arr1,arr2)
  local ret = {};

  local kvRevertArr2 = {};
  for k,v in ipairs(arr2) do
    kvRevertArr2[v] = kvRevertArr2[v] or 0;
    kvRevertArr2[v] = kvRevertArr2[v] + 1;
  end

  for k,v in ipairs(arr1) do
    if not kvRevertArr2[v] then
      ret[#ret+1] = v;
    else
      kvRevertArr2[v] = kvRevertArr2[v] - 1;
      kvRevertArr2[v] = kvRevertArr2[v] > 0 and kvRevertArr2[v] or nil;
    end
  end
  return ret;
end

---
-- 这是一个table的迭代器，使用此迭代器，可以按key的从小到大的顺序对table进行遍历.
--
-- key大小排序规则如下：
--
-- * 如果两个key的类型不一样，则按照类型的大小来排序。
--
-- * 如果两个key的都是number或者都是string类型，则按照number，或者string的大小来排序。
--
-- * 如果两个key都是boolean类型，则按照boolean的大小来比较。
--
-- * 如果两个key不是以上的情况，则按照其转换为字符串的大小来比较。
--
-- 如这样一个table: {1,2,name="zzp",age="0"}， 使用此迭代器将按照1,2,"0","zzp"的顺序得到遍历结果。
--
-- 使用方法为：
--
--      for k,v in orderedPairs(t) do
--          print(k,v)
--      end
--
-- @param #table t 要被迭代的table。
--
-- @return #function,#table,#nil 返回迭代函数，和被迭代的table，和nil。
--
orderedPairs = function(t)
  local cmpMultitype = function(op1, op2)
    local type1, type2 = type(op1), type(op2)
    if type1 ~= type2 then --cmp by type
      return type1 < type2
    elseif type1 == "number" and type2 == "number"
      or type1 == "string" and type2 == "string" then
      return op1 < op2 --comp by default
    elseif type1 == "boolean" and type2 == "boolean" then
      return op1 == true
    else
      return tostring(op1) < tostring(op2)
    end
  end

  local genOrderedIndex = function(t)
    local orderedIndex = {}
    for key in pairs(t) do
      table.insert( orderedIndex, key )
    end
    table.sort( orderedIndex, cmpMultitype ) --### CANGE ###
    return orderedIndex
  end

  local orderedIndex = genOrderedIndex( t );
  local i = 0;
  return function(t)
    i = i + 1;
    if orderedIndex[i]~=nil then
      return orderedIndex[i],t[orderedIndex[i]];
    end
  end,t, nil;
end


end
        

package.preload[ "core.global" ] = function( ... )
    return require('core/global')
end
            

package.preload[ "core/gzip" ] = function( ... )
-- gzip.lua
-- Author: JoyFang
-- Date: 2015-12-23


--------------------------------------------------------------------------------
-- 这个模块提供了加密、解码字符串的方法。
--
-- @module core.gzip
-- @usage local gZip= require 'core.gzip' 

local M={}

---
--对字符串先做gzip压缩，然后base64.
--@param #string str 需要加密的字符串.
--@return #string 对str经过gzip和Base64加密后的字符串.
--@return #nil str为nil/内容为空/加密失败，均返回nil.
M.encodeGzipBase64 = function(str)  
  if str==nil or string.len(str)<1 then
     return nil
  end

   return gzip_compress_base64_encode(str)
end

---
--解码字符串.  
--
--@param #string str str必须是经过encodeGzipBase64加密后的字符串.
--@return #string str经过base64、gzip解码后的字符串.
--@return #nil str为nil/空字符串/未经过encodeGzipBase64加密后的字符串，均返回nil.
M.decodeBase64Gzip = function (str)
   if str==nil or string.len(str)<1 then
     return nil
    end
   return base64_decode_gzip_decompress(str)
end

M.encodeBase64 = function(str)
  if str==nil or string.len(str)<1 then
     return nil
  end
  return base64_encode(str)
end

M.decodeBase64 = function(str)
  if str==nil or string.len(str)<1 then
     return nil
  end
  return base64_decode(str)
end


return M

end
        

package.preload[ "core.gzip" ] = function( ... )
    return require('core/gzip')
end
            

package.preload[ "core/md5" ] = function( ... )
-- md5.lua
-- Author: JoyFang
-- Date: 2015-12-22


--------------------------------------------------------------------------------
-- 这个模块提供了md5加密文件的方法
--
-- @module core.md5
-- @usage local Md5= require 'core.md5' 

local M={}

---
--计算文件的md5。  
--
--@param #string file 文件的绝对路径。
--@return #string 文件的md5。
--@return nil 如果文件的file为nil/file为空字符串/路径不存在/路径包含中文，返回nil。
M.md5File =  function (file)
   if file==nil or string.len(file)<1 then
     return nil 
   end

   return md5_file(file)
end

return M


end
        

package.preload[ "core.md5" ] = function( ... )
    return require('core/md5')
end
            

package.preload[ "core/object" ] = function( ... )

--------------------------------------------------------------------------------
-- 用于模拟面向对象
--
-- @module core.object
-- @return #nil
-- @usage require("core/object")

-- object.lua
-- Author: Vicent Gong
-- Date: 2012-09-30
-- Last modification : 2013-5-29
-- Description: Provide object mechanism for lua


-- Note for the object model here:
--		1.The feature like C++ static members is not support so perfect.
--		What that means is that if u need something like c++ static members,
--		U can access it as a rvalue like C++, but if u need access it
--		as a lvalue u must use [class.member] to access,but not [object.member].
--		2.The function delete cannot release the object, because the gc is based on
--		reference count in lua.If u want to relase all the object memory, u have to
--      set the obj to nil to enable lua gc to recover the memory after calling delete.


---------------------Global functon class ---------------------------------------------------
--Parameters:   super               -- The super class
--              autoConstructSuper   -- If it is true, it will call super ctor automatic,when
--                                      new a class obj. Vice versa.
--Return    :   return an new class type
--Note      :   This function make single inheritance possible.
---------------------------------------------------------------------------------------------

---
-- 用于定义一个类.
--
-- @param #table super 父类。如果不指定，则表示不继承任何类，如果指定，则该指定的对象也必须是使用class()函数定义的类。
-- @param #boolean autoConstructSuper 是否自动调用父类构造函数，默认为true。如果指定为false，若不在ctor()中手动调用super()函数则不会执行父类的构造函数。
-- @return #table class 返回定义的类。
-- @usage
-- Human = class()
-- Human.ctor = function(self)
--  self.m_type = "human"
-- end
-- Human.dtor = function(self)
--  print_string("deleted")
-- end
-- Human.speak = function(self)
--  print_string("I am a " .. self.m_type)
-- end
--
-- Man = class(Human, true)
-- Man.ctor = function(self, name)
--  self.m_sex = "m"
--  self.m_name = name
-- end
function class(super, autoConstructSuper)
  local classType = {};
  classType.autoConstructSuper = autoConstructSuper or (autoConstructSuper == nil);

  if super then
    classType.super = super;
    local mt = getmetatable(super);
    setmetatable(classType, { __index = super; __newindex = mt and mt.__newindex;});
  else
    classType.setDelegate = function(self,delegate)
      self.m_delegate = delegate;
    end
  end

  return classType;
end

---------------------Global functon super ----------------------------------------------
--Parameters:   obj         -- The current class which not contruct completely.
--              ...         -- The super class ctor params.
--Return    :   return an class obj.
--Note      :   This function should be called when newClass = class(super,false).
-----------------------------------------------------------------------------------------

---
-- 手动调用父类的构造函数.
-- 只有当定义类时采用class(super,false)的调用方式时才可以调用此方法，若此时不手动调用则不会执行父类的构造函数。
-- **只能在子类的构造函数中调用。**
-- @param #table obj 类的实例。
-- @param ... 父类构造函数需要传入的参数。
-- @usage
-- local baseClass = class()
-- local derivedClass = class(baseClass,false)
-- derivedClass.ctor = function()
--     super(self) - -此处如果不手动调用super()则不会执行基类的ctor()
-- end
function super(obj, ...)
  do
    local create;
    create =
    function(c, ...)
      if c.super and c.autoConstructSuper then
        create(c.super, ...);
      end
      if rawget(c,"ctor") then
        obj.currentSuper = c.super;
        c.ctor(obj, ...);
      end
    end

    create(obj.currentSuper, ...);
  end
end

---------------------Global functon new -------------------------------------------------
--Parameters: 	classType -- Table(As Class in C++)
-- 				...		   -- All other parameters requisted in constructor
--Return 	:   return an object
--Note		:	This function is defined to simulate C++ new function.
--				First it called the constructor of base class then to be derived class's.
-----------------------------------------------------------------------------------------

---
-- 创建一个类的实例.
-- 调用此方法时会按照类的继承顺序，自上而下调用每个类的构造函数，并返回新创建的实例。
--
-- @param #table classType 类名。  使用class()返回的类。
-- @param ... 构造函数需要传入的参数。
-- @return #table obj 新创建的实例。
-- @usage
-- local me = new(Man, "zzp")
-- me:speak()
function new(classType, ...)
  local obj = {};
  local mt = getmetatable(classType);
  setmetatable(obj, { __index = classType; __newindex = mt and mt.__newindex;});
  do
    local create;
    create =
    function(c, ...)
      if c.super and c.autoConstructSuper then
        create(c.super, ...);
      end
      if rawget(c,"ctor") then
        obj.currentSuper = c.super;
        c.ctor(obj, ...);
      end
    end

    create(classType, ...);
  end
  obj.currentSuper = nil;
  return obj;
end

---------------------Global functon delete ----------------------------------------------
--Parameters: 	obj -- the object to be deleted
--Return 	:   no return
--Note		:	This function is defined to simulate C++ delete function.
--				First it called the destructor of derived class then to be base class's.
-----------------------------------------------------------------------------------------

---
-- 删除某个实例.
-- 类似c++里的delete ，会按照继承顺序，依次自下而上调用每个类的析构方法。
--
-- **需要留意的是，删除此实例后，lua里该对象的引用(obj)依然有效，再次使用可能会发生无法预知的意外。**
--
-- @param #table obj 需要删除的实例。
function delete(obj)
  do
    local destory =
    function(c)
      while c do
        if rawget(c,"dtor") then
          c.dtor(obj);
        end

        c = getmetatable(c);
        c = c and c.__index;
      end
    end
    destory(obj);
  end
end

---------------------Global functon delete ----------------------------------------------
--Parameters:   class       -- The class type to add property
--              varName     -- The class member name to be get or set
--              propName    -- The name to be added after get or set to organize a function name.
--              createGetter-- if need getter, true,otherwise false.
--              createSetter-- if need setter, true,otherwise false.
--Return    :   no return
--Note      :   This function is going to add get[PropName] / set[PropName] to [class].
-----------------------------------------------------------------------------------------

---
-- 为类定义一个property (java里的getter/setter).
-- 会自动为类生成getter/setter方法。
--
-- @param #table class 使用class()方法定义的类。
-- @param #string varName 类里的成员变量名。
-- @param #string propName 属性名，也就是生成的方法setXX/getXX里的'XX'。
-- @param #boolean createGetter 是否生成getter。
-- @param #boolean createSetter 是否生成setter。<br>
-- 如果createGetter不为false或nil，则给class生成一个get#propName()方法,可以获取class的varName的值。<br>
-- 如果createSetter不为false或nil，则给class生成一个set#propName(Value)方法，可以设置class的varName为Value。
-- @usage
-- property(Man, "m_name", "Name", true, false)
-- local me = new(Man, "zzp")
-- print_string(me:getName())
function property(class, varName, propName, createGetter, createSetter)
  createGetter = createGetter or (createGetter == nil);
  createSetter = createSetter or (createSetter == nil);

  if createGetter then
    class[string.format("get%s",propName)] = function(self)
      return self[varName];
    end
  end

  if createSetter then
    class[string.format("set%s",propName)] = function(self,var)
      self[varName] = var;
    end
  end
end

---------------------Global functon delete ----------------------------------------------
--Parameters:   obj         -- A class object
--              classType   -- A class
--Return    :   return true, if the obj is a object of the classType or a object of the
--              classType's derive class. otherwise ,return false;
-----------------------------------------------------------------------------------------

---
-- 判断一个对象是否是某个类(包括其父类)的实例.
-- 类似java里的instanceof。
--
-- @param obj 需要判断的对象。
-- @param classType 使用class()方法定义的类。
-- @return #boolean 若obj是classType的实例，则返回true；否则，返回false。
-- @usage
-- local me = new(Man, "zzp")
-- if typeof(me, Man) == true then
--     print_string("me is instance of Man")
-- end
function typeof(obj, classType)
  if type(obj) ~= type(table) or type(classType) ~= type(table) then
    return type(obj) == type(classType);
  end

  while obj do
    if obj == classType then
      return true;
    end
    obj = getmetatable(obj) and getmetatable(obj).__index;
  end

  return false;
end

---------------------Global functon delete ----------------------------------------------
--Parameters:   obj         -- A class object
--Return    :   return the object's type class.
-----------------------------------------------------------------------------------------

---
-- 通过一个对象反向得到此对象的类.
--
-- @param obj 对象。
-- @return class 此对象的类。
-- @return #nil 如果obj不是某个类的对象，则返回nil。
function decltype(obj)
  if type(obj) ~= type(table) or obj.autoConstructSuper == nil then
    --error("Not a class obj");
    return nil;
  end

  if rawget(obj,"autoConstructSuper") ~= nil then
    --error("It is a class but not a class obj");
    return nil;
  end

  local class = getmetatable(obj) and getmetatable(obj).__index;
  if not class then
    --error("No class reference");
    return nil;
  end

  return class;
end

end
        

package.preload[ "core.object" ] = function( ... )
    return require('core/object')
end
            

package.preload[ "core/prop" ] = function( ... )

--------------------------------------------------------------------------------
-- prop是应用在drawing上的属性.
--
-- 引擎内的属性prop对象是用于对控件特性的描述，包括了颜色、点大小、线宽、透明度、2D变化（平移、旋转、缩放）、索引、起止点等等，属性的值可以是固定值，也可以是动态变化的值。
--
-- @module core.prop
-- @return #nil
-- @usage require("core/prop")

-- prop.lua
-- Author: Vicent Gong
-- Date: 2012-09-21
-- Last modification : 2013-5-29
-- Description: provide basic wrapper for attributes which will be attached to a drawing

require("core/object");
require("core/constants");

---------------------------------------------------------------------------------------------
-----------------------------------[CLASS] PropBase------------------------------------------
---------------------------------------------------------------------------------------------

---
-- prop的基类，无法直接使用.它是所有其它属性类的父类。
--
-- @type PropBase
PropBase = class();

---
-- 返回prop的唯一id.
--
-- @function [parent=#PropBase] getID
-- @param self
-- @return #number 属性的Id。
property(PropBase,"m_propID","ID",true,false);


---
-- 构造函数.
--
-- @param self
PropBase.ctor = function(self)
  self.m_propID = prop_alloc_id();
end


---
-- 析构函数.
--
-- @param self
PropBase.dtor = function(self)
  prop_free_id(self.m_propID);
end


---
-- 设置一个debugName,便于调试.
--
-- 在出错的时候所打印出来的错误信息，会把debugName也给打印出来。
--
-- @param self
-- @param #string name debugName。
PropBase.setDebugName = function(self, name)
  self.m_debugName = name;
  prop_set_debug_name(self.m_propID,name or "");
end

---
-- 返回debugName.
--
-- @param self
-- @param #string name debugName。
PropBase.getDebugName = function(self)
  return self.m_debugName;
end


---------------------------------------------------------------------------------------------
-----------------------------------[CLASS] PropTranslate-------------------------------------
---------------------------------------------------------------------------------------------


---
-- PropTranslate是对平移属性的一个简单封装，只要传入必要的参数就可创建一个2D平移属性.
--
-- @type PropTranslate
-- @extends #PropBase
PropTranslate = class(PropBase);


---
-- 构造函数.
--
-- @param self
-- @param core.anim#AnimBase animX x轴方向的平移变换的动画。详见： @{core.anim#AnimBase}
-- @param core.anim#AnimBase animY y轴方向的平移变换的动画。详见： @{core.anim#AnimBase}
PropTranslate.ctor = function(self, animX, animY)
  prop_create_translate(0, self.m_propID,
    animX and animX:getID() or -1,
    animY and animY:getID() or -1
  );
end

---
-- 析构函数.
--
-- @param self
PropTranslate.dtor = function(self)
  prop_delete(self.m_propID);
end


---------------------------------------------------------------------------------------------
-----------------------------------[CLASS] PropRotate----------------------------------------
---------------------------------------------------------------------------------------------

---
-- 旋转属性.
--
-- 根据指定的中心点来顺时针旋转。
-- @type PropRotate
-- @extends #PropBase
PropRotate = class(PropBase);

---
-- 构造函数.
--
-- 根据指定的中心点来顺时针旋转的属性。
--
-- @param self
-- @param core.anim#AnimBase anim 角度变化的动画。
-- @param #number center 旋转的中心点。取值：[```kNotCenter```](core.constants.html#kNotCenter)（取此值时，不需要传入x,y的值）、[```kCenterDrawing```](core.constants.html#kCenterDrawing)（取此值时，不需要传入x,y的值）、[```kCenterXY```](core.constants.html#kCenterXY)（取此值时，要传入x,y的值，默认为0，0）。详见：<a href="core.drawing.html#00703">指定drawing的中心点。</a>
-- @param #number x 相对于drawing左上角(详见：<a href="core.drawing.html#0070301">drawing的左上角</a> )的x轴偏移。只有center的取值为[```kCenterXY```](core.constants.html#kCenterXY)的时候才有效。默认值为0。
-- @param #number y 相对于drawing左上角(详见：<a href="core.drawing.html#0070301">drawing的左上角</a> )的y轴偏移。只有center的取值为[```kCenterXY```](core.constants.html#kCenterXY)的时候才有效。默认值为0。
PropRotate.ctor = function(self, anim, center, x, y)
  prop_create_rotate(0, self.m_propID, anim:getID(),
    center or kNotCenter, x or 0, y or 0);
end

---
-- 析构函数.
--
-- @param self
PropRotate.dtor = function(self)
  prop_delete(self.m_propID);
end


---------------------------------------------------------------------------------------------
-----------------------------------[CLASS] PropScale-----------------------------------------
---------------------------------------------------------------------------------------------


---
-- 缩放属性.
--
-- 根据指定的中心点来缩放。
-- @type PropScale
-- @extends #PropBase
PropScale = class(PropBase);


---
-- 构造函数.
--
-- @param self
-- @param core.anim#AnimBase animX x轴方向的缩放动画。
-- @param core.anim#AnimBase animY y轴方向的缩放动画。
-- @param #number center 缩放的中心点。取值：[```kNotCenter```](core.constants.html#kNotCenter)（取此值时，不需要传入x,y的值）、[```kCenterDrawing```](core.constants.html#kCenterDrawing)（取此值时，不需要传入x,y的值）、[```kCenterXY```](core.constants.html#kCenterXY)（取此值时，要传入x,y的值，默认为0，0）。详见：<a href="core.drawing.html#00703">指定drawing的中心点。</a>
-- @param #number x 相对于drawing左上角(详见：<a href="core.drawing.html#0070301">drawing的左上角</a> )的x轴偏移。只有center的取值为[```kCenterXY```](core.constants.html#kCenterXY)的时候才有效。默认值为0。
-- @param #number y 相对于drawing左上角(详见：<a href="core.drawing.html#0070301">drawing的左上角</a> )的y轴偏移。只有center的取值为[```kCenterXY```](core.constants.html#kCenterXY)的时候才有效。默认值为0。
PropScale.ctor = function(self, animX, animY, center, x, y)
  prop_create_scale(0, self.m_propID,
    animX and animX:getID() or -1,
    animY and animY:getID() or -1,
    center or kNotCenter, x or 0, y or 0);
end

---
-- 析构函数.
--
-- @param self
PropScale.dtor = function(self)
  prop_delete(self.m_propID);
end


---------------------------------------------------------------------------------------------
-----------------------------------[CLASS] PropTranslateSolid--------------------------------
---------------------------------------------------------------------------------------------

---
-- 静态的位移属性。直接达到最终值，不会有动画展示。
--
-- @type PropTranslateSolid
-- @extends #PropBase
PropTranslateSolid = class(PropBase);

---
-- 构造函数.
--
-- @param self
-- @param #number x 相对于drawing当前位置的左上角(详见：<a href="core.drawing.html#0070301">drawing的左上角</a> )的x轴的偏移。
-- @param #number y 相对于drawing当前位置的左上角(详见：<a href="core.drawing.html#0070301">drawing的左上角</a> )的y轴的偏移。
PropTranslateSolid.ctor = function(self, x, y)
  prop_create_translate_solid(0, self.m_propID, x, y);
end

---
-- 设置平移属性，即在x轴，和y轴方向上的平移。
--
-- @param self
-- @param #number x  相对于drawing当前位置的左上角(详见：<a href="core.drawing.html#0070301">drawing的左上角</a> )的x轴的偏移。
-- @param #number y  相对于drawing当前位置的左上角(详见：<a href="core.drawing.html#0070301">drawing的左上角</a> )的y轴的偏移。
PropTranslateSolid.set = function(self, x, y)
  prop_set_translate_solid(self.m_propID, x, y);
end

---
-- 析构函数.
--
-- @param self
PropTranslateSolid.dtor = function(self)
  prop_delete(self.m_propID);
end


---------------------------------------------------------------------------------------------
-----------------------------------[CLASS] PropRotateSolid-----------------------------------
---------------------------------------------------------------------------------------------


---
-- 静态的旋转属性。没有旋转的过程.
--
-- 根据指定的中心点来顺时针旋转。
-- @type PropRotateSolid
-- @extends #PropBase
PropRotateSolid = class(PropBase)

---
-- 构造函数.
--
-- @param self
-- @param #number angle360 旋转角度。
-- @param #number center 旋转的中心点。取值：[```kNotCenter```](core.constants.html#kNotCenter)（取此值时，不需要传入x,y的值）、[```kCenterDrawing```](core.constants.html#kCenterDrawing)（取此值时，不需要传入x,y的值）、[```kCenterXY```](core.constants.html#kCenterXY)（取此值时，要传入x,y的值，默认为0，0）。详见：<a href="core.drawing.html#00703">指定drawing的中心点</a>
-- @param #number x 相对于drawing左上角(详见：<a href="core.drawing.html#0070301">drawing的左上角</a> )的x轴偏移。只有center的取值为[```kCenterXY```](core.constants.html#kCenterXY)的时候才有效。默认值为0。
-- @param #number y 相对于drawing左上角(详见：<a href="core.drawing.html#0070301">drawing的左上角</a> )的y轴偏移。只有center的取值为[```kCenterXY```](core.constants.html#kCenterXY)的时候才有效。默认值为0。
PropRotateSolid.ctor = function(self, angle360, center, x, y)
  prop_create_rotate_solid(0, self.m_propID, angle360,
    center or kNotCenter,x or 0,y or 0);
end

---
-- 重新设置旋转角度.
--
-- @param self
-- @param #number angle360 旋转角度。
PropRotateSolid.set = function(self, angle360)
  prop_set_rotate_solid(self.m_propID, angle360);
end

---
-- 析构函数.
--
-- @param self
PropRotateSolid.dtor = function(self)
  prop_delete(self.m_propID);
end


---------------------------------------------------------------------------------------------
-----------------------------------[CLASS] PropScaleSolid------------------------------------
---------------------------------------------------------------------------------------------


---
-- 静态的缩放属性。直接达到最终值，没有动画。
--
-- @type PropScaleSolid
-- @extends #PropBase
PropScaleSolid = class(PropBase)


---
-- 构造函数.
--
-- @param self
-- @param #number scaleX x轴的缩放比例。1.0为drawing原始的大小。该值越大，看到的drawing越大。
-- @param #number scaleY y轴的缩放比例。1.0为drawing原始的大小。该值越大，看到的drawing越大。
-- @param #number center 缩放的中心点。取值：[```kNotCenter```](core.constants.html#kNotCenter)（取此值时，不需要传入x,y的值）、[```kCenterDrawing```](core.constants.html#kCenterDrawing)（取此值时，不需要传入x,y的值）、[```kCenterXY```](core.constants.html#kCenterXY)（取此值时，要传入x,y的值，默认为0，0）。详见：<a href="core.drawing.html#00703">指定drawing的中心点</a>
-- @param #number x 相对于drawing左上角(详见：<a href="core.drawing.html#0070301">drawing的左上角</a> )的x轴偏移。只有center的取值为[```kCenterXY```](core.constants.html#kCenterXY)的时候才有效。默认值为0。
-- @param #number y 相对于drawing左上角(详见：<a href="core.drawing.html#0070301">drawing的左上角</a> )的y轴偏移。只有center的取值为[```kCenterXY```](core.constants.html#kCenterXY)的时候才有效。默认值为0。
PropScaleSolid.ctor = function(self, scaleX, scaleY, center, x, y)
  prop_create_scale_solid(0, self.m_propID, scaleX, scaleY,
    center or kNotCenter,x or 0,y or 0);
end

---
-- 重新设置缩放比例.
--
--
-- @param self
-- @param #number scaleX x轴的缩放比例。1.0为drawing原始的大小。该值越大，看到的drawing越大。
-- @param #number scaleY y轴的缩放比例。1.0为drawing原始的大小。该值越大，看到的drawing越大。
PropScaleSolid.set = function(self, scaleX, scaleY)
  prop_set_scale_solid(self.m_propID, scaleX, scaleY);
end


---
-- 析构函数.
PropScaleSolid.dtor = function(self)
  prop_delete(self.m_propID);
end


---------------------------------------------------------------------------------------------
-----------------------------------[CLASS] PropColor-----------------------------------------
---------------------------------------------------------------------------------------------

---
-- 颜色变化的属性.
--
-- @type PropColor
-- @extends #PropBase
PropColor = class(PropBase);

---
-- 构造函数.
--
-- @param self
-- @param core.anim#AnimBase animR RGB颜色中的R分量的值的动画。详见：@{core.anim#AnimBase}。
-- @param core.anim#AnimBase animG RGB颜色中的G分量的值的动画。详见：@{core.anim#AnimBase}。
-- @param core.anim#AnimBase animB RGB颜色中的B分量的值的动画。详见：@{core.anim#AnimBase}。
--
-- 如果以上Anim可变值为double类型，则颜色范围为[0.0,1.0]；
--
--如果以上Anim可变值为int类型，则颜色范围为[0,255]；
--
--如果以上Anim可变值为index类型，则颜色范围为[0.0,1.0]；
PropColor.ctor = function(self, animR, animG, animB)
  prop_create_color(0, self.m_propID,
    animR and animR:getID() or -1,
    animG and animG:getID() or -1,
    animB and animB:getID() or -1);
end

---
-- 析构函数.
--
-- @param self
PropColor.dtor = function(self)
  prop_delete(self.m_propID);
end


---------------------------------------------------------------------------------------------
-----------------------------------[CLASS] PropTransparency----------------------------------
---------------------------------------------------------------------------------------------

---
-- 透明度变化的属性.
--
-- @type PropTransparency
-- @extends #PropBase
PropTransparency = class(PropBase);


---
-- 构造函数.
--
-- @param self
-- @param core.anim#AnimBase anim 透明度变化的动画。详见：@{core.anim#AnimBase}。透明度的取值：[0,1]。0表示透明，1表示不透明，0.5表示半透明。
-- 如果添加了多个此属性，最终只有sequence值最大的有效。详见[sequence的影响]( http://engine.by.com:8080/hosting/data/1451465498787_8655701166692189097.html)第一点的第三条。
PropTransparency.ctor = function(self, anim)
  prop_create_transparency(0, self.m_propID, anim:getID());
end

---
-- 析构函数.
-- @param self
PropTransparency.dtor = function(self)
  prop_delete(self.m_propID);
end


---------------------------------------------------------------------------------------------
-----------------------------------[CLASS] PropClip------------------------------------------
---------------------------------------------------------------------------------------------


---
-- 裁剪的属性。
--
-- @type PropClip
-- @extends #PropBase
PropClip = class(PropBase)


---
-- 构造函数.
--
-- @param self
-- @param core.anim#AnimBase animX x值变化的动画。x值参照@{core.drawing#DrawingBase.setClip}方法里的x。
-- @param core.anim#AnimBase animY y值变化的动画。y值参照@{core.drawing#DrawingBase.setClip}方法里的y。
-- @param core.anim#AnimBase animW w值变化的动画。y值参照@{core.drawing#DrawingBase.setClip}方法里的w。
-- @param core.anim#AnimBase animH h值变化的动画。y值参照@{core.drawing#DrawingBase.setClip}方法里的h。
--
--
-- 如果添加了多个此属性，最终只有sequence值最大的有效。详见[sequence的影响]( http://engine.by.com:8080/hosting/data/1451465498787_8655701166692189097.html)第一点的第三条。
PropClip.ctor = function(self, animX, animY, animW, animH)
  prop_create_clip(0, self.m_propID,
    animX and animX:getID() or -1,
    animY and animY:getID() or -1,
    animW and animW:getID() or -1,
    animH and animH:getID() or -1);
end

---
-- 析构函数.
--
-- @param self
PropClip.dtor = function(self)
  prop_delete(self.m_propID);
end


---------------------------------------------------------------------------------------------
-----------------------------------[CLASS] PropImageIndex------------------------------------
---------------------------------------------------------------------------------------------



---
-- 索引属性.
-- 每一个DrawingImage可以包含多个image，指定显示某一张。使用此特性可以很容易实现一个帧动画。
-- 参考： @{core.drawing#DrawingImage}
--
-- @type PropImageIndex
-- @extends #PropBase
PropImageIndex = class(PropBase)

---
-- 构造函数.
--
-- 当一个drawing对象添加了多个贴图资源时，可以用来实现帧动画。
--
-- @param self
-- @param core.anim#AnimBase anim 指定索引变化的动画。详见：@{core.anim#AnimBase}
PropImageIndex.ctor = function(self, anim)
  prop_create_image_index(0, self.m_propID, anim:getID());
end


---
-- 析构函数.
--
-- @param self
PropImageIndex.dtor = function(self)
  prop_delete(self.m_propID);
end

end
        

package.preload[ "core.prop" ] = function( ... )
    return require('core/prop')
end
            

package.preload[ "core/res" ] = function( ... )

--------------------------------------------------------------------------------
--
-- Res 全部都是用于加载资源的，其中包括图片、文本、以及给引擎内部使用的部分数组数据.
-- 
-- 概念介绍：
-- ---------------------------------------------------------------------------------------
--
-- <a name="001" id="001" ></a>
-- **1.纹理的像素格式**
-- 
-- 纹理的像素格式描述了像素数据存储所用的格式,定义了像素在内存中的编码方式,是标识图片加载到内存之后各部分的所占的位数。
--  
-- 引擎中有以下取值：
-- 
-- * [```kRGBA8888```](core.constants.html#kRGBA8888)（32位像素格式）: 支持透明，最占用内存，但显示画面效果最佳。
-- 
-- * [```kRGBA4444```](core.constants.html#kRGBA4444)（16位像素格式）: 支持透明，比[```kRGBA8888```](core.constants.html#kRGBA8888)节约一半内存，画面效果差一些。
-- 
-- * [```kRGBA5551```](core.constants.html#kRGBA5551)（16位像素格式）: 支持透明，比[```kRGBA8888```](core.constants.html#kRGBA8888)节约一半内存，画面效果差一些。
-- 
-- * [```kRGB565```](core.constants.html#kRGB565)（16位像素格式）:不支持透明，比[```kRGBA8888```](core.constants.html#kRGBA8888)节约一半内存，画面效果差一些。
-- 
--  纹理的像素格式的取值决定OpenGl读取位图资源时所用的像素格式，参考[glTexImage2D](https://www.khronos.org/opengles/sdk/docs/man/xhtml/glTexImage2D.xml)函数的 ```type``` 参数。
-- 
-- <a name="002" id="002" ></a>
-- **2.纹理的过滤方式**
-- 
-- 贴图时，三维空间里面的多边形经过坐标变换、投影、光栅化等过程，变成二维屏幕上的一组象素时，对每个象素需要到相应位图中进行采样，这个过程就称为过滤.     
--    
-- 引擎中有以下取值：
-- 
-- [```kFilterNearest```](core.constants.html#kFilterNearest): 最临近插值。对应opengl的[glTexParameter](https://www.khronos.org/opengles/sdk/docs/man/xhtml/glTexParameter.xml)中param对应的取值```GL_NEAREST```。
--  
-- [```kFilterLinear```](core.constants.html#kFilterLinear):线性过滤。对应opengl的[glTexParameter](https://www.khronos.org/opengles/sdk/docs/man/xhtml/glTexParameter.xml)中param对应的取值```GL_LINEAR```。
-- 
-- **最临近插值**一般用于位图大小与贴图的三维图形的大小差不多的时候。
-- 
-- **线性过滤**采用的计算方法比最临近插值复杂，但是能取得更为平滑的效果。
--
-- @module core.res
-- @return #nil
-- @usage require("core/res")

-- res.lua
-- Author: Vicent Gong
-- Date: 2012-09-20
-- Last modification : 2015-12-7
-- Description: provide basic wrapper for resources manager

require("core/object");
require("core/constants");

---------------------------------------------------------------------------------------------
-----------------------------------[CLASS] ResBase-------------------------------------------
---------------------------------------------------------------------------------------------
local s_pathPickerFunc = nil
local s_formatPickerFunc = nil
local s_filterPickerFunc = nil
local s_align = nil
local s_fontName = nil
local s_fontSize = nil
local s_g = nil
local s_r = nil
local s_b = nil
---
-- res基类.**本身无法直接使用.**
--
-- @type ResBase
ResBase = class();

---
-- 返回ResBase对象的id.    
-- 每个ResBase对象都有自己唯一的Id，是一个32位带符号整数，在创建对象的时候由引擎自动分配;  
-- @function [parent=#ResBase] getID
-- @param self
-- @return #number 返回res的id.

property(ResBase, "m_resID", "ID", true, false);

---
-- 构造函数.
--
-- @param self
ResBase.ctor = function(self)
    self.m_resID = res_alloc_id();
end

---
-- 析构函数.
--
-- @param self
ResBase.dtor = function(self)
    res_free_id(self.m_resID);
end


---
-- 设置一个debugName，便于调试.如果出现错误日志中会打印出这个名字，便于定位问题.
--
-- @param self
-- @param #string name 设置的debugName.
ResBase.setDebugName = function(self, name)
    res_set_debug_name(self.m_resID, name or "");
    self.m_debugName=name or ""
end


---
-- 返回debugName.
-- @return #string 返回debugName.
ResBase.getDebugName = function(self)
    return self.m_debugName
end

---------------------------------------------------------------------------------------------
-----------------------------------[CLASS] ResImage------------------------------------------
---------------------------------------------------------------------------------------------


---
-- 引擎位图资源.
-- 
-- @type ResImage
-- @extends #ResBase
ResImage = class(ResBase);

---
-- 获得位图资源的宽度.
--
-- @function [parent=#ResImage] getWidth
-- @param self
-- @return #number 位图资源的宽度.
property(ResImage, "m_width", "Width", true, false);

---
-- 获得位图资源的高度.
--
-- @function [parent=#ResImage] getHeight
-- @param self
-- @return #number 返回位图资源的高度.
property(ResImage, "m_height", "Height", true, false);


---
-- 设置图片的默认纹理像素格式.  
-- @param #function func 设置纹理像素格式的函数.  
-- 函数定义如下：  
--     function(configPath, fileName)
--         return kRGBA8888
--     end  
-- **configPath**:图片的目录。 
-- **fileName**:图片的路径。  
-- 
-- 此函数的作用是设置configPath目录下的名为fileName的图片的默认纹理像素格式(仅支持png格式)。
--   
-- func的返回值可取值 [```kRGBA8888```](core.constants.html#kRGBA8888)、 [```kRGBA4444```](core.constants.html#kRGBA4444)、[```kRGBA5551```](core.constants.html#kRGBA5551)、[```kRGB565```](core.constants.html#kRGB565).
--   
-- ResImage.setFormatPicker在@{#ResImage.ctor}或@{#ResImage.setFile}执行前调用有效.
--   
ResImage.setFormatPicker = function(func)
    s_formatPickerFunc = func;
end

---
-- 设置图片的默认纹理过滤方式.   
-- @param #function func 设置过滤方式的函数.  
--    函数定义如下:   
--      function(configPath, fileName)            
--          return kFilterLinear    
--      end   
-- **configPath**:图片的目录。
-- **fileName**:图片的路径。
-- 
-- 此函数的作用是设置configPath目录下的名为fileName的图片的默认纹理过滤方式(仅支持png格式),
--   
-- func的返回值可取值[```kFilterNearest```](core.constants.html#kFilterNearest)、[```kFilterLinear```](core.constants.html#kFilterLinear).   
ResImage.setFilterPicker = function(func)
    s_filterPickerFunc = func;
end

---
-- 设置图片的默认目录.  
-- 
-- 引擎会在此设置的目录下去搜索相应的图片。
-- 
-- 此函数会在@{#ResImage.ctor}时被调用.
--
-- @param #function func 设置图片的目录的函数.
--   
--  函数定义如下：  
--     function(fileName) 
--         return `old_version/images_backup/`
--     end  
-- 
ResImage.setPathPicker = function(func)
    s_pathPickerFunc = func;
end

---
--构造函数调用此函数.
local ResImage__onInit = function (self, file, format, filter)
    local fileName;
    if type(file) == "table" then
        fileName = file.file;
        self.m_subTexX = file.x;
        self.m_subTexY = file.y;
        self.m_subTexW = file.width;
        self.m_subTexH = file.height;
        self.m_subOffsetX = file.offsetX;
        self.m_subOffsetY = file.offsetY;
        self.m_subTexUtW = file.utWidth;
        self.m_subTexUtH = file.utHeight;
        self.m_subTexRotated = file.rotated;
    else
        fileName = file;
    end

    local configPath = s_pathPickerFunc and s_pathPickerFunc(fileName) or "";

    self.m_fileName = configPath .. fileName;
    self.m_filter = self.m_filter
    or filter
    or(s_filterPickerFunc and s_filterPickerFunc(configPath, fileName))
    or kFilterNearest;
    self.m_format = self.m_format
    or format
    or(s_formatPickerFunc and s_formatPickerFunc(configPath, fileName))
    or kRGBA8888;

    self.m_width = self.m_width or 0
    self.m_height = self.m_height or 0
    if res_create_image(0, self.m_resID, self.m_fileName, self.m_format, self.m_filter) == 0 then
        if self.m_subTexRotated == true and self.m_subTexUtW == nil then
            self.m_width = self.m_subTexH
            self.m_height = self.m_subTexW
        else
            self.m_width = self.m_subTexUtW or self.m_subTexW or res_get_image_width(self.m_resID);
            self.m_height = self.m_subTexUtH or self.m_subTexH or res_get_image_height(self.m_resID);
        end
    else
        --self.m_width = -1
        --self.m_height = -1
    end
end

---
-- 构造函数.
--
-- @param self
-- @param file 图片路径，可以传入string和table两种类型的参数.
-- 
-- 1.当file类型是string时,即图片的路径.仅支持png格式.
--
-- 2.当file类型为table时，表示截取图片上某一矩形区域作为资源，此时file必须包含以下字段：    
-- <a name="0001" id="0001" ></a>    
-- 
-- * file：文件路径。类型string.
-- 
-- 若通过@{#ResImage.setPathPicker}设置过默认目录，则会去此目录下搜名为```file```的图片。
--       
-- 若从未调用过@{#ResImage.setPathPicker}，则会在引擎默认的目录下寻找名为```file```的图片;  
--       
-- 其中，func为最后一次调用@{#ResImage.setPathPicker}所传的参数.   
-- 
-- * x: 相对于图片左上角的横坐标。类型number.取值范围：x>=0且x+width<=图片的宽度.
-- 
-- * y: 相对于图片左上角的纵坐标。类型number.取值范围：y>=0且y+height<=图片的高度.
--
-- * width：图片上矩形截取区域的宽度，类型number.取值范围：w>=0且x+width<=图片的宽度.
-- 
-- * height: 图片上矩形截取区域的高度，类型number.取值范围：h>=0且y+height<=图片的高度.
-- 
-- 如下图，假设O为图片坐标原点，P的坐标(40,80)，传入的file为{file="bg/cards.png", x=40, y=80, width=120, height=90}:  
-- 
-- ![](http://engine.by.com:8080/hosting/data/1450235731994_5827158023213736441.png)  
-- 
-- 则会以P为起点截取宽高分别为w、h(单位像素)的矩形区域作为图片资源使用.  
-- 
-- @param #number format 纹理的像素格式.详见：<a href = "#001">纹理的像素格式。</a>   
-- 
-- ```format```若为nil,则取@{#ResImage.setFomatPicker}设置的默认值，若未通过@{#ResImage.setFomatPicker}设置，则默认取值[```kRGBA8888```](core.constants.html#kRGBA8888).         
-- 其中，func为最后一次调用@{#ResImage.setFomatPicker}所传的参数.  
--    
-- @param #number filter 纹理的过滤方式.详见：<a href = "#002">纹理的过滤方式。</a> 
-- 
-- ```filter```若为nil，则取@{#ResImage.setFilterPicker}设置的默认值，若未通过@{#ResImage.setFilterPicker}设置，则默认取值为[```kFilterNearest```](core.constants.html#kFilterNearest);      
-- 其中，func为最后一次调用@{#ResImage.setFilterPicker}所传的参数.  
--   
ResImage.ctor = function(self, file, format, filter)
    ResImage__onInit(self,file, format, filter)
end

ResImage.isValid = function(self)
    --return self.m_width >= 0 and self.m_height >= 0
    return true
end


---
-- 获取位图资源的信息.
-- 
-- @param self
-- @return #number, #number, #number, #number  若构造时@{#ResImage.ctor}的```file```参数的类型为table，则返回```file.x, file.y,file.width, file.height, file.offsetX, file.offsetY, file.utWidth, file.utHeight, file.rotated```的值.
-- @return #nil,#nil,#nil,#nil 若构造时@{#ResImage.ctor}的```file```参数的类型不是table，则全部返回nil.
ResImage.getSubTextureCoord = function(self)
    return self.m_subTexX, self.m_subTexY, self.m_subTexW, self.m_subTexH,self.m_subOffsetX,self.m_subOffsetY,self.m_subTexUtW,self.m_subTexUtH,self.m_subTexRotated;
end

---
-- 更换所用的位图.  
-- 注：尽管此过程会在引擎内部重新创建新的位图资源对象，但是由于位图资源的ID不变，所以通常无需处理相关对象。
--
-- @param self
-- @param file 图片路径.可以传入string和table两种类型的参数.
-- 
-- 1.当file类型是string时,即图片的路径.仅支持png格式.
--
-- 2.当file类型为table时，表示截取图片上某一矩形区域作为资源，此时file必须包含以下字段：    
-- <a name="0001" id="0001" ></a>    
-- 
-- * file：文件路径。类型string.
-- 
-- 若通过@{#ResImage.setPathPicker}设置过默认目录，则会去此目录下搜名为```file```的图片。
--       
-- 若从未调用过@{#ResImage.setPathPicker}，则会在引擎默认的目录下寻找名为```file```的图片;  
--       
-- 其中，func为最后一次调用@{#ResImage.setPathPicker}所传的参数.   
-- 
-- * x: 相对于图片左上角的横坐标。类型number.取值范围：x>=0且x+width<=图片的宽度.
-- 
-- * y: 相对于图片左上角的纵坐标。类型number.取值范围：y>=0且y+height<=图片的高度.
--
-- * width：图片上矩形截取区域的宽度，类型number.取值范围：w>=0且x+width<=图片的宽度.
-- 
-- * height: 图片上矩形截取区域的高度，类型number.取值范围：h>=0且y+height<=图片的高度.
-- 
-- 如下图，假设O为图片坐标原点，P的坐标(40,80)，传入的file为{file="bg/cards.png", x=40, y=80, width=120, height=90}:  
-- 
-- ![](http://engine.by.com:8080/hosting/data/1450235731994_5827158023213736441.png)  
-- 
-- 则会以P为起点截取宽高分别为w、h(单位像素)的矩形区域作为图片资源使用. 
-- @param #number format 纹理的像素格式.详见：<a href = "#001">纹理的像素格式。</a>   
-- 
-- ```format```若为nil,则取@{#ResImage.setFomatPicker}设置的默认值，若未通过@{#ResImage.setFomatPicker}设置，则默认取值[```kRGBA8888```](core.constants.html#kRGBA8888).         
-- 其中，func为最后一次调用@{#ResImage.setFomatPicker}所传的参数.      
-- @param #number filter 纹理的过滤方式.详见：<a href = "#002">纹理的过滤方式。</a> 
-- 
-- ```filter```若为nil，则取@{#ResImage.setFilterPicker}设置的默认值，若未通过@{#ResImage.setFilterPicker}设置，则默认取值为[```kFilterNearest```](core.constants.html#kFilterNearest);      
-- 其中，func为最后一次调用@{#ResImage.setFilterPicker}所传的参数.   
ResImage.setFile = function(self, file, format, filter)
    ResImage.dtor(self);

    self.m_subTexX = nil;
    self.m_subTexY = nil;
    self.m_subTexW = nil;
    self.m_subTexH = nil;
    self.m_subOffsetX = nil;
    self.m_subOffsetY = nil;
    self.m_subTexUtW = nil;
    self.m_subTexUtH = nil;
    self.m_subTexRotated = nil;

    ResImage.ctor(self, file, format, filter)
end

---
-- 析构函数.
-- 在析构的过程中，会删除此位图资源，清理位图资源所占用的内存.
ResImage.dtor = function(self)
    res_delete(self.m_resID);
end



--------------------------------------------------------------------------------------------
---------------------------------[CLASS] ResCapturedImage-----------------------------------
--------------------------------------------------------------------------------------------

---
--截取屏幕并生成位图.
--
-- @type ResCapturedImage
-- @extends #ResImage
ResCapturedImage = class(ResImage,false)

---
--构造函数调用此方法.
local ResCapturedImage__onInit = function (self)
    self.m_subTexX =nil;
    self.m_subTexY =nil;
    self.m_subTexW =nil;
    self.m_subTexH =nil;
    self.m_subOffsetX = nil;
    self.m_subOffsetY = nil;
    self.m_subTexUtW = nil;
    self.m_subTexUtH = nil;
    self.m_subTexRotated = nil;
 
    self.m_filter = self.m_filter
    or filter
    or kFilterNearest;
    self.m_format = self.m_format
    or format
    or kRGBA8888;
      
    if res_create_framebuffer_image(0, self.m_resID,self.m_format, self.m_filter) == 0 then
        self.m_width = res_get_image_width(self.m_resID) or System.getLayoutWidth();
        self.m_height =  res_get_image_height(self.m_resID) or System.getLayoutHeight();
    else
        self.m_width = -1
        self.m_height = -1
    end
end


---
-- 构造函数.
--
-- @param self
-- @param #number format OpenGl读取位图资源时所用的像素格式.     
-- ResImage.setFormatPicker函数在此无效.
-- @param #number filter 位图资源的过滤方式.   
-- ResImage.setFilterPicker函数在此无效.
ResCapturedImage.ctor = function (self, format, filter)
    self.m_resID = res_alloc_id();
    ResCapturedImage__onInit(self)
end

---
-- override父类方法.  
--
-- @param self 
ResCapturedImage.setFile = function(self)
     
end

---
-- 析构函数.
ResCapturedImage.dtor = function(self)
    res_delete(self.m_resID);
end


---------------------------------------------------------------------------------------------
-----------------------------------[CLASS] ResText-------------------------------------------
---------------------------------------------------------------------------------------------

---
-- 引擎文字位图.
-- 
-- @type ResText
-- @extends #ResBase
ResText = class(ResBase);


---
-- 获取文字位图的宽度.
--
-- @function [parent=#ResText] getWidth
-- @param self
-- @return #number 文字位图的宽度.
property(ResText, "m_width", "Width", true, false);

---
-- 获取文字位图的高度.
--
-- @function [parent=#ResText] getHeight
-- @param self
-- @return #number 文字位图的高度.
property(ResText, "m_height", "Height", true, false);

---
-- 设置默认的文字颜色.
-- 
-- 如未使用此函数进行设置，则会使用引擎自己设置的默认值。
--
-- @param #number r 文字的RGB颜色的R分色.取值范围：[0,255].
-- @param #number g 文字的RGB颜色的G分色.取值范围：[0,255].
-- @param #number b 文字的RGB颜色的B分色.取值范围：[0,255].
ResText.setDefaultColor = function(r, g, b)
    s_r = r;
    s_g = g;
    s_b = b;
end

---
-- 设置字体和字号.在构造函数@{#ResText.ctor}之前调用.
--
--调用时机无限制;一旦调用，则文字的有默认字体名称、字体大小.直到再次调用更改.
-- @param #string fontName 字体名称.
-- (需要有对应文件名的字体文件,放在fonts目录下).
-- @param #number fontSize 字体大小.实际大小依据不同的平台而定，例如Windows和Android平台大小可能会不同.
ResText.setDefaultFontNameAndSize = function(fontName, fontSize)
    s_fontName = fontName;
    s_fontSize = fontSize;
end

---
-- 设置文字默认对齐方式 .  
--
-- @param #number align 文字对齐方式。有以下取值：
-- 
-- <a name = "0002" id = "0002"></a>
-- 
-- * [```kAlignCenter```](core.constants.html#kAlignCenter)居中对齐。  
-- * [```kAlignTop```](core.constants.html#kAlignTop)　顶部居中对齐。   
-- * [```kAlignTopRight```](core.constants.html#kAlignTopRight)右上角对齐。    
-- * [```kAlignRight```](core.constants.html#kAlignRight)右部居中对齐。   
-- * [```kAlignBottomRight```](core.constants.html#kAlignBottomRight)右下角对齐。    
-- * [```kAlignBottom```](core.constants.html#kAlignBottom)下部居中对齐。   
-- * [```kAlignBottomLeft```](core.constants.html#kAlignBottomLeft)左下角对齐。  
-- * [```kAlignLeft```](core.constants.html#kAlignLeft)左部居中对齐。    
-- * [```kAlignTopLeft```](core.constants.html#kAlignTopLeft)顶部居中对齐。  
-- 对齐方式如下图：     
-- ![](http://engine.by.com:8080/hosting/data/1450267951324_840123041012274695.png) 
ResText.setDefaultTextAlign = function(align)
    s_align = align;
end

---
-- 构造函数.
--
-- @param self
-- @param #string str 文字位图展示的文字.
-- @param #number width 指定文字位图的宽度 ,取值不小于0.  
-- @param #number height 指定文字位图的高度,取值不小于0.  
-- @param #number align 文字对齐方式.取值见：<a href = "#0002">文字对齐方式。</a> 
--  
--  注：只有所有文字没有完全占满width*height的矩形空间，即空出的行高>=一行的高度且max(每行空出的宽度)>=max(每个文字的宽度)，align的设置才有效。
-- @param #string fontName 字体名称.
-- 
-- ```fontName```为nil时,如果通过@{#ResText.setDefaultFontNameAndSize}设置过默认值，则取其设置的默认值；
-- 
-- 若未通过@{#ResText.setDefaultFontNameAndSize}设置，则为默认值[```kDefaultFontName```](core.constants.html#kDefaultFontName)。 
--  
-- **默认名称依据不同的平台而定，例如Windows和Android平台默认字体名称可能会不同**.
-- 
-- @param #number fontSize 字体大小.
-- 
-- ```fontSize```若为nil,如果通过@{#ResText.setDefaultFontNameAndSize}设置过默认值，则取其设置的默认值；
-- 
-- 若未通过@{#ResText.setDefaultFontNameAndSize}设置，则为默认值[```kDefaultFontSize```](core.constants.html#kDefaultFontSize)。 
-- 
-- **默认字体大小依据不同的平台而定，例如Windows和Android平台默认字体大小可能会不同；且即使默认大小相同，显示效果也依平台会略有不同**.
-- @param #number r 文字的RGB颜色的R分色.取值范围：[0,255].
-- 
-- r为nil时,如果通过@{#ResText.setDefaultColor}设置过默认值，则取其设置的默认值；
-- 
-- 若未通过@{#ResText.setDefaultColor}设置，则默认值为[```kDefaultTextColorR```](core.constants.html#kDefaultTextColorR)。
-- 
-- @param #number g 文字的RGB颜色的G分色.取值范围：[0,255].
-- 
-- g为nil时,如果通过@{#ResText.setDefaultColor}设置过默认值，则取其设置的默认值；
-- 
-- 若未通过@{#ResText.setDefaultColor}设置，则默认值为[```kDefaultTextColorG```](core.constants.html#kDefaultTextColorG)。
--  
-- @param #number b 文字的RGB颜色的B分色.取值范围：[0,255].
-- 
-- b为nil时,如果通过@{#ResText.setDefaultColor}设置过默认值，则取其设置的默认值；
-- 
-- 若未通过@{#ResText.setDefaultColor}设置，则默认值为[```kDefaultTextColorB```](core.constants.html#kDefaultTextColorB)。
-- 
-- @param #number multiLines 是否多行:0表示单行;1表示多行，如果一行不足以展示所有的文字，则自动换行. 
-- 
-- **单行文字**：  
-- 根据fontSize和str计算一行能容纳所有文字的最小宽度和最小高度，则
-- 文字位图的实际宽度=Max(最小宽度,width); 实际高度=Max(最小高度,height);   
-- 
-- **多行文字**：  
-- 根据fontSize和width计算出一行能容纳的最小字数，若width<8，则默认为8；若未能容纳，则自动换行并扩充高度直至填满.  
-- 
-- 扩充的高度即为最小高度.
-- 
-- 1.文字位图实际宽度为width，但width不得小于8. 
--  
-- 2.文字位图实际高度=Max(最小高度,height).  
-- 
-- 单行和双行，多余部分均为透明.
ResText.ctor = function(self, str, width, height, align, fontName, fontSize, r, g, b, multiLines)
    self.m_str = str;
    self.m_width = width;
    self.m_height = height;
    self.m_r = r or s_r or kDefaultTextColorR;
    self.m_g = g or s_g or kDefaultTextColorG;
    self.m_b = b or s_b or kDefaultTextColorB;
    self.m_align = align or s_align or kAlignLeft;
    self.m_font = fontName or s_fontName or kDefaultFontName;
    self.m_fontSize = fontSize or s_fontSize or kDefaultFontSize;
    self.m_multiLines = multiLines;

    if res_create_text_image(0, self.m_resID, self.m_str, self.m_width, self.m_height,
    self.m_r, self.m_g, self.m_b, self.m_align, self.m_font, self.m_fontSize, self.m_multiLines) == 0 then
        self.m_width = res_get_image_width(self.m_resID);
        self.m_height = res_get_image_height(self.m_resID);
    else
        self.m_width = -1
        self.m_height = -1
    end
end

---
-- 更换展示的文字.
-- 注：尽管此过程会在引擎内部重新创建新的位图资源对象，但是由于位图资源的ID不变，所以通常无需处理相关对象.  
-- @param self
-- @param #string str 文字位图展示的文字.
-- @param #number width 指定文字位图的宽度 ,取值不小于0.  
-- @param #number height 指定文字位图的高度，取值不小于0.     
-- @param #string fontName 字体名称.```fontName```若为nil,则为构造时所建立的值.  
-- @param #number fontSize 字体大小.```fontSize```若为nil,则为构造时所建立的值..  
-- @param #number r 文字的RGB颜色的R分色.取值范围：[0,255].r若为nil,则为构造时所建立的值.
-- @param #number g 文字的RGB颜色的G分色.取值范围：[0,255].g若为nil,则为构造时所建立的值.
-- @param #number b 文字的RGB颜色的B分色.取值范围：[0,255].b若为nil,则为构造时所建立的值.
ResText.setText = function(self, str, width, height, r, g, b)
    ResText.dtor(self);
    ResText.ctor(self,
    str or self.m_str,
    width or self.m_width,
    height or self.m_height,
    self.m_align,
    self.m_font,
    self.m_fontSize,
    r or self.m_r,
    g or self.m_g,
    b or self.m_b,
    self.m_multiLines);
end

ResText.setTextAlign = function ( self , align )
    ResText.dtor(self);
    ResText.ctor(self,
    self.m_str,
    self.m_width,
    self.m_height,
    align or self.m_align,
    self.m_font,
    self.m_fontSize,
    self.m_r,
    self.m_g,
    self.m_b,
    self.m_multiLines);
end
---
-- 析构函数.
ResText.dtor = function(self)
    res_delete(self.m_resID);
end


---------------------------------------------------------------------------------------------
-----------------------------------[CLASS] ResDoubleArray------------------------------------
---------------------------------------------------------------------------------------------


---
-- 封装了引擎的double数组.  
-- 
-- @type ResDoubleArray
-- @extends #ResBase
ResDoubleArray = class(ResBase);


---
-- 构造函数.    
-- 初始化一个ResDoubleArray对象，该对象封装了引擎内部的一个double数组；引擎内部创建数组后，用lua数组nums对引擎内部数组进行填充.
-- 
-- @param self.
-- @param #list<#number> 无空洞的数组,如：{1.1, 1.2, 1.3, 1.4}.  
ResDoubleArray.ctor = function(self, nums)
    res_create_double_array(0, self.m_resID, nums);
end

---
-- 清空ResDoubleArray对象的数组,然后用nums的内容填充.    
-- @param self.
-- @param #list<#number> 无空洞的数组,如：{1.1, 1.2, 1.3, 1.4}.  
ResDoubleArray.setData = function(self, nums)
    ResDoubleArray.dtor(self);
    ResDoubleArray.ctor(self, nums);
end

---
-- 析构函数.
--
-- @param self
ResDoubleArray.dtor = function(self)
    res_delete(self.m_resID);
end


---------------------------------------------------------------------------------------------
-----------------------------------[CLASS] ResIntArray---------------------------------------
---------------------------------------------------------------------------------------------


---
-- 封装了引擎的int数组. 
-- @type ResIntArray
-- @extends #ResBase
ResIntArray = class(ResBase);


---
-- 构造函数.    
-- 初始化一个ResIntArray对象，该对象封装了引擎内部的一个int数组；引擎内部创建数组后，用lua数组nums对引擎内部数组进行填充.  
-- 
-- @param self
-- @param #list<#number> nums 无空洞的数组，如:{1,3,5,7}.    
-- 每个数的取值范围为 `[-2147483648,2147483647]`,且必须是整数.
ResIntArray.ctor = function(self, nums)
    res_create_int_array(0, self.m_resID, nums);
end

---
-- 清空ResIntArray对象的数组,然后用nums的内容填充.  
--
-- @param self
-- @param #list<#number> nums 无空洞的int数组，如:{1,3,5,7}.
-- 每个数的取值范围为 `[-2147483648,2147483647]`,且必须是整数.
-- 
ResIntArray.setData = function(self, nums)
    ResIntArray.dtor(self);
    ResIntArray.ctor(self, nums);
end

---
-- 析构函数.
-- @param self
ResIntArray.dtor = function(self)
    res_delete(self.m_resID);
end


---------------------------------------------------------------------------------------------
-----------------------------------[CLASS] ResUShortArray---------------------------------------
---------------------------------------------------------------------------------------------



---
-- 封装了引擎的ushort数组.
-- 
-- @type ResUShortArray
-- @extends #ResBase
ResUShortArray = class(ResBase);


---
-- 构造函数.  
-- 初始化一个ResUShortArray对象，该对象封装了引擎内部的一个ushort数组；引擎内部创建数组后，用lua数组nums对引擎内部数组进行填充.
-- 
-- @param self
-- @param #list<#number> nums 无空洞的ushort数组.如 {1,2,3,4}.
-- 每个数的取值范围为:`[0,65535]`,且必须是整数.
ResUShortArray.ctor = function(self, nums)
    res_create_ushort_array(0, self.m_resID, nums);
end


---
-- 清空ResUShortArray对象的数组,然后用nums的内容填充.    
-- 
-- @param self
-- @param #list<#number> nums 无空洞的数组.如 {1,2,3,4}.  
-- 每个数的取值范围为:`[0,65535]`,且必须是整数.
ResUShortArray.setData = function(self, nums)
    ResUShortArray.dtor(self);
    ResUShortArray.ctor(self, nums);
end

---
-- 析构函数.
--
-- @param self
ResUShortArray.dtor = function(self)
    res_delete(self.m_resID);
end

end
        

package.preload[ "core.res" ] = function( ... )
    return require('core/res')
end
            

package.preload[ "core/sound" ] = function( ... )

--------------------------------------------------------------------------------
-- 播放背景音乐与音效.
-- 音乐(music)：可以是很长的一段声音，一般用于游戏的背景音乐。
--
-- 音效(effect)：是比较短的音乐，一般用于按钮点击、互动表情等声音效果。
--
-- 音量(volume)：描述音乐或者音效的声压大小，声压即声音震动时所产生的压力。
--
-- @module core.sound
-- @return #nil
-- @usage require("core/sound")

-- sound.lua
-- Author: Vicent Gong
-- Date: 2012-09-30
-- Last modification : 2015-12-14
-- Description: provide basic wrapper for sound functions

require("core/constants")
require("core/object")

---
-- Sound类提供的全部都是静态接口，实际上只是对引擎接口的简单封装。
-- 该类主要包含两部分的接口，即对音乐和对音效的操作。
-- 值得注意的是，音乐只能同时存在一个，音效则可以同时存在多个，音乐和音效可以同时存在。
-- 使用方式为Sound.FuncName(), 不必new一个对象再使用。
-- 引擎支持的声音文件格式为：win32下支持mp3, android下支持mp3/ogg, ios下支持mp3/ogg。
--
--
-- @type Sound
Sound = class();

---
-- 预加载音乐.一次只能预加载、播放一个音乐文件。
-- 音乐加载可能需要一些时间，所以可以提前加载(但这不是必须的)。
-- 如在加载界面时预加载音乐文件，之后便可以在显示界面时流畅地播放音乐，避免因加载音乐文件而卡顿。
--
-- @param #string fileName 文件路径+文件名，这个文件路径默认是以 /Resource/audio为根目录的。
Sound.preloadMusic = function(fileName)
  audio_music_preload(fileName);
end

---
-- 播放音乐.
-- 如果之前预加载过或上次加载的没释放就不会再加载了，否则，就会先加载再从头开始播放。
--
-- @param #string fileName 文件路径+文件名，这个文件路径默认是以 /Resource/audio为根目录的。
-- @param #boolean loop 是否循环播放。
Sound.playMusic = function(fileName, loop)
  audio_music_play(fileName,loop and kTrue or kFalse);
end

---
-- 停止播放音乐.
--
-- @param #boolean doUnload 是否释放音乐内存，取值true则释放占用的内存，下次再播放需要重新加载。
Sound.stopMusic = function(doUnload)
  audio_music_stop(doUnload and kTrue or kFalse);
end

---
-- 暂停正在播放的音乐.
-- 如果想从暂停位置恢复播放，则需要调用@{#Sound.resumeMusic}。
-- 如果想从头开始播放，则调用@{#Sound.playMusic}。
Sound.pauseMusic = function()
  audio_music_pause();
end

---
-- 恢复音乐播放.
-- 从上次暂停的位置恢复播放，一般和@{#Sound.pauseMusic}配合使用。
-- 如果音乐没有被暂停，则无效果。
Sound.resumeMusic = function()
  audio_music_resume();
end

---
-- 是否有音乐正在播放.
-- @return #boolean 正在播放则返回true, 否则返回false。
Sound.isMusicPlaying = function()
  return audio_music_is_playing() == 1 and true or false;
end

---
-- 获得音乐的音量值.
-- @return #number 音乐的当前音量值。
Sound.getMusicVolume = function()
  return audio_music_get_volume();
end

---
-- 获得当前系统音乐允许的最大音量.
-- 不同设备上值可能不一样，可以根据这个值去设置实际播放音乐的音量值。
--
-- @return #number 音乐的最大音量值。
Sound.getMusicMaxVolume = function()
  return audio_music_get_max_volume();
end

---
-- 设置音乐的音量.
-- 最灵活的用法是根据@{#Sound.getMusicMaxVolume}返回的值乘以一个百分比作为实参。
--
-- @param #number volume 指定的音量值。
Sound.setMusicVolume = function(volume)
  audio_music_set_volume(volume);
end

---
-- 预加载音效.可以同时预加载、播放多个音效文件 。
-- 音效加载可能需要一些时间，所以可以提前加载(但这不是必须的)。
-- 如在加载界面时预加载音效文件，之后便可以在显示界面时流畅地播放音效，避免因加载音效文件而卡顿。
--
-- @param #string fileName 文件路径+文件名，这个文件路径默认是以 /Resource/audio为根目录的。
Sound.preloadEffect = function(fileName)
  audio_effect_preload(fileName);
end

---
-- 卸载音效.
-- 可释放该音效所占用的内存。
-- @param #string fileName 文件路径+文件名，这个文件路径默认是以 /Resource/audio为根目录的。
Sound.unloadEffect = function(fileName)
  audio_effect_unload(fileName);
end

---
-- 播放音效.
-- 如果之前预加载过或上次加载的没释放就不会再加载了，否则，就会先加载再播放。
--
-- @param #string fileName 文件路径+文件名，这个文件路径默认是以 /Resource/audio为根目录的。
-- @param #boolean loop 是否无限循环播放。
-- @return #number 此音效的唯一id，可使用此id来停止音效的播放。
Sound.playEffect = function(fileName, loop)
  return audio_effect_play(fileName,loop and kTrue or kFalse);
end

---
-- 停止播放音效.
-- 一般情况下都不需要手动调用这个接口停止音效，只有在循环播放音效时才会用到，不会释放对应的内存。
--
-- @param #number id 音效的唯一id，默认id=0，该值是调用@{#Sound.playEffect}返回的。
Sound.stopEffect = function(id)
  audio_effect_stop(id or 0);
end

---
-- 获得音效的音量值.
--
-- @return #number 音效的当前音量值。
Sound.getEffectVolume = function()
  return audio_effect_get_volume();
end


---
-- 获得当前系统音效允许的最大音量.
-- 不同设备上可能不一样，同一种设备的最大音量也是可以修改的，可以根据这个值去设置实际播放音效的音量值。
--
-- @return #number 音效的最大音量值。
Sound.getEffectMaxVolume = function()
  return audio_effect_get_max_volume();
end

---
-- 设置音效的音量.
-- 最灵活的用法是根据@{#Sound.getEffectMaxVolume}返回的值乘以一个百分比作为实参。
--
-- @param #number volume 指定的音量值。
Sound.setEffectVolume = function(volume)
  audio_effect_set_volume(volume);
end

end
        

package.preload[ "core.sound" ] = function( ... )
    return require('core/sound')
end
            

package.preload[ "core/state" ] = function( ... )

--------------------------------------------------------------------------------
-- state是一个状态类，是所有状态的基类。可以理解为一个游戏“场景”，类似于android里的Activity.
-- @{core.stateMachine#StateMachine}会用来管理这些状态。
--
--游戏状态完整的生命周期为：
--
-- ctor -> load -> run -> resume -> pause -> stop -> unload -> dtor
-- @module core.state
-- @return #nil
-- @usage
-- require("core/state")
--
-- HallState = class(State)
--
-- HallState.ctor = function(self)
-- end
--
-- HallState.load = function(self)
--  --仅为演示，实际开发时一般是使用SceneLoader来加载UI编辑器设计的界面
-- 	local root = new(Node)
-- 	root:addToRoot()
-- 	self.m_root_node = root
-- 	return true
-- end
--
-- HallState.unload = function(self)
-- 	delete(self.m_root_node)
-- 	self.m_root_node = nil
-- end
--
-- HallState.stop = function(self)
-- 	self.m_root_node:setVisible(false)
-- end
--
-- HallState.run = function(self)
-- 	self.m_root_node:setVisible(true)
-- end
--
-- HallState.dtor = function(self)
-- end

require("core/object");

-- stateMachine.lua
-- Author: Vicent Gong
-- Date: 2012-11-21
-- Last modification : 2013-05-30
-- Description: Implement base state

---
-- State
--
-- @type State
State = class();

---
-- 构造函数.
-- 创建State实例时调用，此时进入@{#StateStatus.Unloaded}状态。
--
-- 构造函数中不应该包含大量的资源加载。
-- @param self
State.ctor = function(self)
  self.m_status = StateStatus.Unloaded;
end

---
-- 加载state的资源.
-- 此时进入@{#StateStatus.Loading}状态。
-- state的实例创建后，该方法会被不断调用，直至返回true为止，此时进入@{#StateStatus.Loaded}状态。
-- 如果state里的东西过多，可使用此特性来进行分步加载，这样游戏就不会有“卡住”的感觉。
--
-- **该方法不应被手动调用。**
--
-- @param self
State.load = function(self)
  self.m_status = StateStatus.Loading;
end

---
-- state即将进入前台显示，此时进入@{#StateStatus.Started}状态.
--
-- **该方法不应被手动调用。**
--
-- @param self
State.run = function(self)
  self.m_status = StateStatus.Started;
end

---
-- 该方法被调用后进入前台显示状态.
-- 此时进入@{#StateStatus.Resumed}状态。
--
-- 应在此方法中来启动动画，注册事件。
-- **该方法不应被手动调用。**
--
-- @param self
State.resume = function(self)
  self.m_status = StateStatus.Resumed;
end

---
-- state即将进入后台时被调用.
-- 此时进入@{#StateStatus.Paused}状态。
--
-- 应在此方法中暂停动画，取消事件注册。
-- **该方法不应被手动调用。**
--
-- @param self
State.pause = function(self)
  self.m_status = StateStatus.Paused;
end

---
-- state已经进入后台时被调用.
-- 此时进入@{#StateStatus.Stoped}状态。
--
-- **该方法不应被手动调用。**
--
-- @param self
State.stop = function(self)
  self.m_status = StateStatus.Stoped;
end

---
-- state即将退出时被调用.
-- 可在这里进行资源清理操作。此时进入@{#StateStatus.Unloaded}状态。
-- 此方法被调用后state的实例会被delete，之后将无法再被使用。
--
-- **该方法不应被手动调用。**
--
-- @param self
State.unload = function(self)
  self.m_status = StateStatus.Unloaded;
end

---
-- 析构函数.
-- 彻底释放状态资源。
--
-- @param self
State.dtor = function(self)
  self.m_status = StateStatus.Droped;
end

---
-- 获得当前state的状态.
--
-- @param self
-- @return #number 返回当前的state的状态。值为：@{#StateStatus.Unloaded}、@{#StateStatus.Loading}、@{#StateStatus.Loaded}、@{#StateStatus.Started}、@{#StateStatus.Resumed}、@{#StateStatus.Paused}、@{#StateStatus.Stoped}、@{#StateStatus.Droped}。
State.getCurStatus = function(self)
  return self.m_status;
end

---
-- 设置state的状态.
-- **该方法不应被手动调用。**
--
-- @param self
-- @param #number state 状态 取值：@{#StateStatus.Unloaded}、@{#StateStatus.Loading}、@{#StateStatus.Loaded}、@{#StateStatus.Started}、@{#StateStatus.Resumed}、@{#StateStatus.Paused}、@{#StateStatus.Stoped}、@{#StateStatus.Droped}。
State.setStatus = function(self, state)
  self.m_status = state;
end

---
-- state的状态.
--
-- @type StateStatus
-- @field #number Unloaded 未加载(实例刚刚创建)。
-- @field #number Loading 正在加载资源。
-- @field #number Loaded 已经完成资源加载。
-- @field #number Started 即将进入前台显示 (参考android的onStart)。
-- @field #number Resumed 已经进入前台显示，开始启动动画，事件注册。 (参考android的OnResume)。
-- @field #number Paused 进入后台，暂停动画，取消注册事件。 (参考android的onPause)。
-- @field #number Stoped 进入后台，隐藏界面 (参考android的onStop)。
-- @field #number Droped 已经调用delete方法进行销毁 (参考android的onDestroy)。
StateStatus =
  {
    Unloaded  	= 1;
    Loading	  	= 2;
    Loaded		= 3;
    Started		= 4;
    Resumed		= 5;
    Paused		= 6;
    Stoped		= 7;
    Droped		= 8;
  };


---
-- 释放函数的映射表.
State.s_releaseFuncMap =
  {
    [StateStatus.Unloaded] 	= {};
    [StateStatus.Loading] 	= {"unload"};
    [StateStatus.Loaded] 	= {"unload"};
    [StateStatus.Started] 	= {"stop","unload"};
    [StateStatus.Resumed] 	= {"pause","stop","unload"};
    [StateStatus.Paused] 	= {"stop","unload"};
    [StateStatus.Stoped] 	= {"unload"};
    [StateStatus.Droped] 	= {};
  };

end
        

package.preload[ "core.state" ] = function( ... )
    return require('core/state')
end
            

package.preload[ "core/stateMachine" ] = function( ... )

--------------------------------------------------------------------------------
-- 用于管理不同的state（详见：@{core.state}）之间的切换.
--
-- * 一个游戏有很多个state，但特定时间内只有一个state是处于活动状态。state可以理解为舞台或者场景。
--
-- * 开发者只需要关注@{#StateMachine.getInstance}, @{#StateMachine.changeState},@{#StateMachine.pushState},@{#StateMachine.popState}这几个方法，使用这几个方法来进行状态的切换。
--
-- * stateMachine是一个单例模式，二次开发者不能手动创建一个对象，必须通过@{#StateMachine.getInstance}去获得一个全局实例，然后再调用其相应的方法。
--
-- <br/>
-- 下面说明在三种不同的方式切换场景时state各方法被执行的流程。
--
-- 1..**changeState：** 在currentState场景下使用changeState进入到newState场景时，方法执行流程如下：<br/>
-- ![changeState](http://engine.by.com:8080/hosting/data/1452248525715_5519090001263735005.png)<br/>
--
-- 2.**pushState：**  在currentState场景下使用pushState进入到newState场景时，方法执行顺序流程如下：<br/>
-- ![pushState](http://engine.by.com:8080/hosting/data/1452246737566_8837580739284487918.bmp)<br/>
--
-- 3.**popState：** 当前的场景，假设currentState为当前的活动状态，lasteState为currentState之前的状态，popState执行流程如下：<br/>
-- ![popState](http://engine.by.com:8080/hosting/data/1452242842585_1165089751546056283.png)<br/>
--
--
-- Create :创建这个State。<br/>
-- load   :加载State所需要的资源，如果没有加载完会一直加载直到加载完成。<br/>
-- run    :将已经加载好的State显示在屏幕上。<br/>
-- resume :启动动画以及注册事件。<br/>
-- pasue  :暂停动画以及取消事件注册。<br/>
-- stop   : 隐藏界面。  <br/>
-- unload :卸载State所需要的资源。<br/>
-- delete :删除State对象。<br/>
-- @module core.stateMachine
-- @return #nil
-- @usage require("core/stateMachine")

-- stateMachine.lua
-- Author: Vicent Gong
-- Date: 2012-07-09
-- Last modification : 2013-05-30
-- Description: Implement a stateMachine to handle state changing in global

require("core/object");
require("core/state");
require("core/anim");
require("core/constants");

local s_instance = nil
---
--
-- @type StateMachine
StateMachine = class();

---
-- 获得实例，StateMachine以单例形式使用.
--
-- @return #StateMachine 唯一实例。
StateMachine.getInstance = function()
  if not s_instance then
    s_instance = new(StateMachine);
  end

  return s_instance;
end

---
-- 释放单例.
-- 调用此方法会清理所有已经存在的State实例，
-- 此方法不需要关心，无需被使用。
StateMachine.releaseInstance = function()
  delete(s_instance);
  s_instance = nil;
end

---
-- 注册一个场景切换动画处理器.
--
-- @param self 调用者对象。
-- @param #number style 切换动画函数的键值，切换场景时传入该值即使用这种切换效果。
-- @param #function func 处理场景切换动画的函数。
--
-- 在场景切换的时候会调用此函数，函数传入参数为：```func(newStateObj, lastStateObj, callbackObj, callbackFunc)```。
--
-- * newStateObj: 新State的实例对象。
--
-- * lastStateObj: 上一个State的实例对象，如果是刚进入游戏切入第一个场景，则lastStateObj为nil。
--
-- * callbackObj: 状态切换回调函数的对象。
--
-- * callbackFunc: 动画完成后**必须**要手动调用此函数，调用形式为 ```callbackFunc(callbackObj)```。
StateMachine.registerStyle = function(self, style, func)
  self.m_styleFuncMap[style] = func;
end

---
-- 切换到新场景，旧场景会被释放.
-- 现有的所有场景会根据其当前的状态和@{core.state#State.s_releaseFuncMap}的映射表来释放相应的场景。
--
-- @param self 调用者对象。
-- @param #number state 需要被切换到的state。
--	StateMachine在创建一个State的实例时,
--	会以state为索引值，去名为StatesMap的全局变量中找到该state对应的State类，然后创建该类的实例。
--	通常用法如下：
--	通常在statesConfig.lua文件中。
--	States = {
--		Hall = 1,
--		Room = 2
--	}
--	StatesMap = {
--		[States.Hall] = HallState,
--		[States.Room] = RoomState,
--	}
--	在切换到Hall时则调用 StateMachine.getInstance():changeState(States.Hall)。
--	@param #number style 场景切换动画 详见@{#StateMachine.registerStyle}。
--	@param ... 其他参数，创建state的实例时传入构造方法。
StateMachine.changeState = function(self, state, style, ...)
  if not StateMachine.checkState(self,state) then
    return
  end

  local newState,needLoad = StateMachine.getNewState(self,state,...);
  local lastState = table.remove(self.m_states,#self.m_states);

  --release all useless states
  for k,v in pairs(self.m_states) do
    StateMachine.cleanState(self,v);
  end

  --Insert new state
  self.m_states = {};
  self.m_states[#self.m_states+1] = newState;
  StateMachine.switchState(self,needLoad,false,lastState,true,style);
end

---
-- 切换到新场景，旧场景不会被释放.
-- 原有的场景会进入后台，但不会被释放。
--
-- @param self 调用者对象。
-- @param #number state 需要被切换到的state。
-- @param #number style  场景切换动画 详见@{#StateMachine.registerStyle}。
-- @param #boolean isPopupState 如果此值为true，则现处于活动状态的场景的stop方法不会被调用，即不隐藏当前活动的场景。
-- @param ... 其他参数，创建新的state实例时传入构造函数。
StateMachine.pushState = function(self, state, style, isPopupState, ...)
  if not StateMachine.checkState(self,state) then
    return
  end

  local newState,needLoad = StateMachine.getNewState(self,state,...);
  local lastState = self.m_states[#self.m_states];

  self.m_states[#self.m_states+1] = newState;

  StateMachine.switchState(self,needLoad,isPopupState,lastState,false,style);
end

---
-- 切换到上一个保存的场景.
-- 清理当前场景，并恢复上一个场景。
-- 如果当前并没有其他后台状态的场景，则调用此方法会error。
-- 一般使用方法是：使用pushState来进入一个新场景，退出时调用popState则会回到上一个场景。
--
-- @param self 调用者对象。
-- @param #number style 场景切换动画 详见@{#StateMachine.registerStyle}。
StateMachine.popState = function(self, style)
  if not StateMachine.canPop(self) then
    error("Error,no state in state stack\n");
  end

  local lastState = table.remove(self.m_states,#self.m_states);
  StateMachine.switchState(self,false,false,lastState,true,style);
end

---------------------------------private functions-----------------------------------------

---
-- 构造函数.
-- **注：该函数被标记为“private function”，不建议直接调用该函数。**
--
-- @param self 调用者对象。
StateMachine.ctor = function(self)
  self.m_states 			= {};
  self.m_lastState 		= nil;
  self.m_releaseLastState = false;

  self.m_loadingAnim		= nil;
  self.m_isNewStatePopup	= false;

  self.m_styleFuncMap = {};
end

--Check if the current state is the new state and clean unloaded states

---
-- 检测是否需要切换到指定的状态.
-- 如果将要切换到的状态是正在运行的状态，则不会进行任何切换场景的操作。
-- 如果前一个state并没有完成加载，则会被清理掉。
--
-- **注：该函数被标记为“private function”，不建议直接调用该函数。**
--
-- @param self 调用者对象。
-- @param #number state 需要被检查的State。
-- @return #boolean 返回true即当前的state不是正在运行的State需要进行场景切换操作；返回false则当前的state是正在运行的State，不需要进行场景切换操作。
StateMachine.checkState = function(self, state)
  delete(self.m_loadingAnim);
  self.m_loadingAnim = nil;

  local lastState = self.m_states[#self.m_states];
  if not lastState then
    return true;
  end
  if lastState.state == state then
    return false;
  end

  local lastStateObj = lastState.stateObj;
  if lastStateObj:getCurStatus() <= StateStatus.Loaded then
    StateMachine.cleanState(self,lastState);
    self.m_states[#self.m_states] = nil;
    return StateMachine.checkState(self,state);
  else
    return true;
  end
end

---
-- 获取一个新的State实例.
-- 如果已经存在，则会直接使用，不会创建新的。
--
-- **注：该函数被标记为“private function”，不建议直接调用该函数。**
--
-- @param self 调用者对象。
-- @param #number state 需要被获取的State。
-- @param ... 新实例的构造参数。
-- @return #table,#boolean 新的State，是否需要加载新的State实例对象（返回true,需要加载新的State，返回false不需要加载新的State）。
StateMachine.getNewState = function(self, state, ...)
  local nextStateIndex;
  for i,v in ipairs(self.m_states) do
    if v.state == state then
      nextStateIndex = i;
      break;
    end
  end

  local nextState;
  if nextStateIndex then
    nextState = table.remove(self.m_states,nextStateIndex);
  else
    nextState = {};
    nextState.state = state;
    nextState.stateObj = new(StatesMap[state],...);
  end

  return nextState,(not nextStateIndex);
end

---
-- 是否有处于后台状态的state用来进行popState操作.
-- **注：该函数被标记为“private function”，不建议直接调用该函数。**
--
-- @param self 调用者对象。
-- @return #boolean  返回true表示可以进行popState操作，返回false表示不能进行popState操作。
StateMachine.canPop = function(self)
  if #self.m_states < 2 then
    return false;
  else
    return true;
  end
end

---
-- 开始进行state切换操作.
-- **注：该函数被标记为“private function”，不建议直接调用该函数。**
--
-- @param self 调用者对象。
-- @param #boolean needLoadNewState 新的state是否需要进行load操作。needLoadNewState为true则需要加载；needLoadNewState为false则不需要加载。
-- @param #boolean isNewStatePopup 切换前的state是否执行stop操作。isNewStatePopup为true，则切换前的state不会被stop即不会被隐藏；isNewStatePopup为false，则切换前的state会执行stop，即会被隐藏。
-- @param #table lastState 切换前的state。
-- @param #boolean needReleaseLastState 是否需要释放切换前的state。
-- @param #number style 场景切换动画 详见@{#StateMachine.registerStyle}。
StateMachine.switchState = function(self, needLoadNewState, isNewStatePopup,
  lastState, needReleaseLastState,
  style)

  self.m_isNewStatePopup = isNewStatePopup;

  self.m_lastState = lastState;
  self.m_releaseLastState = needReleaseLastState;
  self.m_style = style;

  StateMachine.pauseState(self,self.m_lastState);

  if needLoadNewState then
    self.m_loadingAnim = new(AnimInt,kAnimRepeat,0,1,1);
    self.m_loadingAnim:setEvent(self,StateMachine.loadAndRun);
  else
    StateMachine.run(self);
  end
end

---
-- 对新切入的state执行load和run操作.
-- 该方法是一个每帧循环调用的AnimInt的回调函数。
-- 每帧调用一次state的load函数，直至返回true时再调用state的run函数。
--
-- **注：该函数被标记为“private function”，不建议直接调用该函数。**
--
-- @param self 调用者对象。
StateMachine.loadAndRun = function(self)
  local stateObj = self.m_states[#self.m_states].stateObj;
  if stateObj:load() then
    delete(self.m_loadingAnim);
    self.m_loadingAnim = nil;
    stateObj:setStatus(StateStatus.Loaded);
    StateMachine.run(self);
  end
end

---
-- 执行需要切入的state的run方法.
-- 在@{#StateMachine.loadAndRun}之后，调用state的run方法。
-- 随后调用场景切换动画的处理函数(如果有)。
--
-- **注：该函数被标记为“private function”，不建议直接调用该函数。**
--
-- @param self 调用者对象。
StateMachine.run = function(self)
  StateMachine.runState(self,self.m_states[#self.m_states]);

  local newStateObj = self.m_states[#self.m_states].stateObj;
  if self.m_lastState and self.m_style and self.m_styleFuncMap[self.m_style] then
    self.m_styleFuncMap[self.m_style](newStateObj,self.m_lastState.stateObj,self,StateMachine.onSwitchEnd);
  else
    StateMachine.onSwitchEnd(self);
  end
end

---
-- 切换场景的最后一步，处理当前场景和上一场景的最终状态.
-- 处理切换前的场景，可能有3种情况：
--
-- 1.changeState时，切换前的场景进行释放。
--
-- 2.pushState时，isPopupState参数为false时，执行切换前的场景的stop函数。
--
-- 3.pushState，并且isPopupState参数为true时，参考@{#StateMachine.pushState}，什么也不做。
--
--
-- 最后执行新场景的resume函数。
--
-- **注：该函数被标记为“private function”，不建议直接调用该函数。**
--
-- @param self 调用者对象。
StateMachine.onSwitchEnd = function(self)
  if self.m_lastState then
    if self.m_releaseLastState then
      StateMachine.cleanState(self,self.m_lastState);
    elseif self.m_isNewStatePopup then

    else
      self.m_lastState.stateObj:stop();
    end
  end

  self.m_lastState = nil;
  self.m_releaseLastState = false;

  local newState = self.m_states[#self.m_states].stateObj;
  newState:resume();
end

---
-- 对一个state执行清理工作.
--
-- 现有的所有场景会根据其当前的状态和@{core.state#State.s_releaseFuncMap}的映射表来执行相应的函数并释放场景。
--
-- 如：
--
-- 一个state处于 @{core.state#StateStatus.Resumed}状态，则会执行pause->stop->unload->delete。
--
-- 一个state处于 @{core.state#StateStatus.Paused}状态，则会执行stop->unload->delete。
--
-- **注：该函数被标记为“private function”，不建议直接调用该函数。**
--
-- @param self 调用者对象。
-- @param #table state 需要被清理的state。
StateMachine.cleanState = function(self, state)
  if not (state and state.stateObj) then
    return
  end

  local obj = state.stateObj;
  for _,v in ipairs(State.s_releaseFuncMap[obj:getCurStatus()]) do
    obj[v](obj);
  end
  delete(obj);
end

---
-- 执行一个state的run函数.
-- 只有当处于StateStatus.Loaded或StateStatus.Stoped状态时才会执行。
--
-- **注：该函数被标记为“private function”，不建议直接调用该函数。**
--
-- @param self 调用者对象。
-- @param #table state 将要被运行的state。
StateMachine.runState = function(self, state)
  if not (state and state.stateObj) then
    return
  end

  local obj = state.stateObj;
  if obj:getCurStatus() == StateStatus.Loaded
    or obj:getCurStatus() == StateStatus.Stoped  then
    obj:run();
  end
end

---
-- 执行一个state的pause方法.
-- 只有当state处于StateStatus.Resumed状态时才会执行。
--
-- **注：该函数被标记为“private function”，不建议直接调用该函数。**
--
-- @param self 调用者对象。
-- @param #table state 将要被暂停的state。
StateMachine.pauseState = function(self, state)
  if not (state and state.stateObj) then
    return
  end

  local obj = state.stateObj;
  if obj:getCurStatus() == StateStatus.Resumed then
    obj:pause();
  end
end

---
-- 析构函数.
-- 会清理掉所有已经存在的state。
--
-- @param self 调用者对象。
StateMachine.dtor = function(self)
  for i,v in pairs(self.m_states) do
    StateMachine.cleanState(self,v);
  end

  self.m_states = {};
end

end
        

package.preload[ "core.stateMachine" ] = function( ... )
    return require('core/stateMachine')
end
            

package.preload[ "core/system" ] = function( ... )

--------------------------------------------------------------------------------
-- 用于一些系统设置或获得系统配置.
-- 如获得图片路径、设置设计分辨率等。
--
-- @module core.system
-- @return #nil
-- @usage require("core/system")

-- system.lua
-- Author: Vicent Gong
-- Date: 2012-09-30
-- Last modification : 2013-05-30
-- Description: provide basic wrapper for system functions

require("core/object");
require("core/constants")
require("core/res")

local s_resolution   = nil
local s_screenWidth  = nil
local s_screenHeight = nil
local s_layoutWidth  = nil
local s_layoutHeight = nil
local s_layoutScale  = nil
local s_screenScaleWidth = nil
local s_screenScaleHeight = nil
local s_platform = nil
local s_language = nil
local s_country = nil

---
-- @type System
System = {}

---
-- 获得屏幕分辨率.
--
-- @return #string resolution 格式如：1280x720。
System.getResolution = function()
    s_resolution = s_resolutions or sys_get_string("resolution");
    return s_resolution
end


---
-- 获得屏幕宽。
--
-- @return #number width 屏幕宽(像素)。
System.getScreenWidth = function()
    s_screenWidth = s_screenWidth or sys_get_int("screen_width",0);
    return s_screenWidth
end

---
-- 获得屏幕高。
--
-- @return #number height 屏幕高。
System.getScreenHeight = function()
    s_screenHeight = s_screenHeight or sys_get_int("screen_height",0);
    return s_screenHeight
end

System.resetScreenSize = function()
    s_screenWidth = nil
    s_screenHeight = nil
end

---
-- 设置设计分辨率的宽(用于进行屏幕适配)。
--
-- @param #number width 设计分辨率的宽。
System.setLayoutWidth = function(width)
    s_layoutWidth = width;
end

---
-- 设置设计分辨率的高(用于进行屏幕适配)。
--
-- @param #number height 设计分辨率的高。
System.setLayoutHeight = function(height)
    s_layoutHeight = height;
end

---
-- 获得设计分辨率的宽。
--
-- @param #number width 如果未设置过，则返回屏幕宽。
System.getLayoutWidth = function()
    return s_layoutWidth or System.getScreenWidth();
end

---
-- 获得设计分辨率的高。
--
-- @param #number height 如果未设置过，则返回屏幕高。
System.getLayoutHeight = function()
    return s_layoutHeight or System.getScreenHeight();
end

---
-- 获得适配缩放比例.
-- 如果未设置过设计分辨率，则比例为1。
-- 否则为屏幕大小和设计分辨率大小的比例，以宽高中小的为准。
--
-- @return #number 适配缩放比例。
System.getLayoutScale = function()
    local xScale = System.getScreenWidth() / System.getLayoutWidth();
    local yScale = System.getScreenHeight() / System.getLayoutHeight();
    s_layoutScale = xScale>yScale and yScale or xScale;
    return s_layoutScale;
end

---
-- 获得经过缩放计算后的屏幕宽.
-- 屏幕实际宽/缩放比例。
--
-- @return #number 经过缩放计算后的屏幕宽。
System.getScreenScaleWidth = function()
    s_screenScaleWidth = System.getScreenWidth() / System.getLayoutScale();
    return s_screenScaleWidth;
end

---
-- 获得经过缩放计算后的屏幕高.
-- 屏幕实际高度/缩放比例。
--
-- @return #number 经过缩放计算后的屏幕高。
System.getScreenScaleHeight = function()
    s_screenScaleHeight = System.getScreenHeight() / System.getLayoutScale();
    return s_screenScaleHeight;
end


---
-- 获得当前平台类型.
-- win32/android/ios/wp8。
--
-- @return #string 平台类型。
System.getPlatform = function()
    s_platform = s_platform or sys_get_string("platform");
    return s_platform;
end

---
-- 获得当前系统的语言.
-- 此值根据各平台的接口获取。
--
-- @return #string 系统的语言。如在win32中文系统下，返回值是zh。
System.getLanguage = function()
    s_language = s_language or sys_get_string("language");
    return s_language;
end

---
-- 获得当前系统的国家.
-- 此值根据各平台的接口获取。
--
-- @return #string country 如在win32下返回为CN。
System.getCountry = function()
    s_country = s_country or sys_get_string("country");
    return s_country;
end

---
-- 获得在执行此代码之前已经创建的res(@{core.res})的数量。
--
-- @return #number res的数量。
System.getResNum = function()
    return sys_get_int("res_num",0);
end

---
-- 获得在执行此代码之前已经创建的anim(@{core.anim})的数量。
--
-- @return #number anim的数量。
System.getAnimNum = function()
    return sys_get_int("anim_num",0);
end

---
-- 获得在执行此代码之前已经创建的prop(@{core.prop})的数量。
--
-- @return #number prop的数量。
System.getPropNum = function()
    return sys_get_int("prop_num",0);
end

---
-- 获得在执行此代码之前已经创建的drawing(@{core.drawing})的数量。
--
-- @return #number drawing的数量。
System.getDrawingNum = function()
    return sys_get_int("drawing_num",0);
end

---
-- 获得一个唯一的uuid.
-- 此uuid在第一次启动时生成
--
-- @return #string 唯一的uuid。
System.getGuid = function()
    return sys_get_string("uuid");
end

---
-- 设置上一次的lua错误信息.
-- 此方法一般不应该手动调用。
-- @param #string strValue 错误信息。
-- @return #string 上一次的lua错误信息。
System.setLuaError = function(strValue)
    return sys_set_string("last_lua_error",strValue);
end

---
-- 获得上一次lua的错误信息。
--
-- @return #string 上一次lua的错误信息。
System.getLuaError = function()
    return sys_get_string("last_lua_error");
end

---
-- ---
-- 当前这一帧循环花了多少时间。
--
-- @return #number 当前帧循环所花的世界（单位：毫秒）。
System.getTickTime = function()
    return sys_get_int("tick_millseconds",0);
end


---
-- ---
-- 返回从第一次调用此函数到当前调用此函数的时间。
--
-- @return #number 返回从第一次调用此函数到当前调用此函数的时间（单位：毫秒）。
System.getBootTime = function (  )
    return sys_get_int("frame_time",0);
end

---
-- 获取windows_guid，同@{#System.getGuid}。
-- @return #string 获取windows的uid.
System.getWindowsGuid = function()
    return sys_get_string("windows_guid");
end

---
-- 设置win32环境下的文字编码.
--
-- @param #string code 编码格式。
System.setWin32TextCode = function(code)
    GameString.setWin32Code(code);
end

---
-- 设置默认文字的字体名和字号.
-- 详见： @{core.res#ResText.setDefaultFontNameAndSize}。
--
-- @param #string fontName 字体名称。
-- @param #number fontSize 字体大小.实际大小依据不同的平台而定，例如Windows和Android平台大小可能会不同.
System.setDefaultFontNameAndSize = function(fontName, fontSize)
    ResText.setDefaultFontNameAndSize(fontName,fontSize);
end

---
-- 设置默认文字的颜色.
-- 详见： @{core.res#ResText.setDefaultColor}。
--
-- @param #number r 文字的RGB颜色的R分色.取值范围：[0,255].
-- @param #number g 文字的RGB颜色的G分色.取值范围：[0,255].
-- @param #number b 文字的RGB颜色的B分色.取值范围：[0,255].
System.setDefaultTextColor = function(r, g, b)
    ResText.setDefaultColor(r,g,b);
end

---
-- 设置文字默认对齐方式 .
-- 
-- @param #number align 文字对齐方式。
-- 详见：@{core.res#ResText.setDefaultTextAlign}。
System.setDefaultTextAlign = function(align)
    ResText.setDefaultTextAlign(align);
end

---
-- 设置图片的默认目录.  
-- 
-- @param #function func 设置图片的目录的函数。
-- 详见：@{core.res#ResImage.setPathPicker}。
System.setImagePathPicker = function(func)
    ResImage.setPathPicker(func);
end

---
-- 设置图片的默认纹理像素格式.
--   
-- @param #function func 设置纹理像素格式的函数.
-- 详见：@{core.res#ResImage.setFormatPicker}。
System.setImageFormatPicker = function(func)
    ResImage.setFormatPicker(func);
end

---
-- 设置图片的默认纹理过滤方式. 
-- 
-- @param #function func 设置过滤方式的函数.  
-- 
-- 详见：@{core.res#ResImage.setFilterPicker}。
System.setImageFilterPicker = function(func)
    ResImage.setFilterPicker(func);
end

-------------------------------------------------

---
-- 获得外部存储里scripts的目录.
-- android环境下是 /sdcard/.PACKAGENAME/scripts/。
--
-- @return #string scripts目录。
System.getStorageScriptPath = function()
    return sys_get_string("storage_user_scripts") or "";
end

---
-- 获得外部存储里images的目录.
-- android环境下是 /sdcard/.PACKAGENAME/images/。
--
-- @return #string images的目录。
System.getStorageImagePath = function()
    return sys_get_string("storage_user_images") or "";
end

---
-- 获得外部存储里audio的目录.
-- android环境下是 /sdcard/.PACKAGENAME/audio/。
--
-- @return #string audio的目录。
System.getStorageAudioPath = function()
    return sys_get_string("storage_user_audio") or "";
end

---
-- 获得外部存储里font的路径.
-- android环境下是 /sdcard/.PACKAGENAME/fonts/。
--
-- @return #string font的路径。
System.getStorageFontPath = function()
    return sys_get_string("storage_user_fonts") or "";
end

---
-- 获得外部存储里xml的路径.
-- android环境下是 /sdcard/.PACKAGENAME/xml/。
--
-- @return #string xml的路径。
System.getStorageXmlPath = function()
    return sys_get_string("storage_xml") or "";
end

---
-- 获得外部存储里update的路径.
-- android环境下是 /sdcard/.PACKAGENAME/update/。
--
-- @return #string update的路径。
System.getStorageUpdatePath = function()
    return sys_get_string("storage_update_zip") or "";
end

---
-- 获得外部存储里dict的路径.
-- android环境下是 /sdcard/.PACKAGENAME/dict/。
--
-- @return #string dict的路径。
System.getStorageDictPath = function()
    return sys_get_string("storage_dic") or "";
end

---
-- 获得外部存储里log的路径.
-- android环境下是 /sdcard/.PACKAGENAME/log/。
--
-- @return #string log的路径。
System.getStorageLogPath = function()
    return sys_get_string("storage_log") or "";
end


---
-- 获得外部存储里user的路径.
-- android环境下是 /sdcard/.PACKAGENAME/user/
--
-- @return #string user的路径。
System.getStorageUserPath = function()
    return sys_get_string("storage_user_root") or "";
end


---
-- 获得外部存储里temp的路径.
-- android环境下是 /sdcard/.PACKAGENAME/tmp/。
--
-- @return #string temp的路径。
System.getStorageTempPath = function()
    return sys_get_string("storage_tmp") or "";
end

---
-- win32下返回Resource所在目录。
-- Android下返回Activity.getInstance().getApplication().getFilesDir().getAbsolutePath()，路径是/data/data/com.boyaa.xxx/files/。
--
-- @return #string app的路径。
System.getStorageAppRoot = function()
    return sys_get_string("storage_app_root") or "";
end

---
-- win32下返回Resource\Inner所在目录。
-- Android下返回Activity.getInstance().getApplication().getFilesDir().getAbsolutePath()，路径是/data/data/com.boyaa.xxx/files/。
--
-- @return #string app的inner路径。
System.getStorageInnerRoot = function()
    return sys_get_string("storage_inner_root") or "";
end

---
--win32下返回Resource\Outer所在目录；
--Android下返回: 某些设备上路径是/mnt/sdcard/.PACKAGENAME/，也有些是/storage/emulated/0/，后者比较多。
--
-- @return #string 路径。
System.getStorageOuterRoot = function()
    return sys_get_string("storage_outer_root") or "";
end


---
-- 删除一个文件。
--
-- @param #string filePath 文件全路径。
-- @return #boolean  是否删除成功。返回true则删除成功，返回false则删除失败。
System.removeFile = function(filePath)
    if os.isexist(filePath) == false then
        return false
    end
    return os.remove(filePath);
end


---
-- 复制一个文件。
--
-- @param #string srcFilePath 要复制的文件的全路径。
-- @param #string destFilePath 目标路径。
-- @return #boolean  是否复制成功。返回true复制成功，返回false复制失败。
System.copyFile = function(srcFilePath,destFilePath)
    return os.cp(srcFilePath,destFilePath);
end

---
-- 获得文件的大小.
-- 需要确保有权限访问此文件。
-- @param #string filePath 文件全路径。
-- @return #number 文件大小(字节)。如果文件不存在或无权限访问，则返回-1。
System.getFileSize = function(filePath)
    if os.isexist(filePath)== false then
        return -1
    end
    return  os.filesize(filePath)
end

---
-- 添加一个图片搜索路径.
-- 添加的路径优先级会放到最高。
--
-- @param #string path 完整的路径。
System.pushFrontImageSearchPath = function(path)
    sys_set_string("push_front_images_path", path);
end

---
-- 添加一个声音搜索路径.
-- 添加的路径优先级会放到最高。
--
-- @param #string path 完整的路径。
System.pushFrontAudioSearchPath = function(path)
    sys_set_string("push_front_audio_path", path);
end

---
-- 添加一个字体搜索路径.
-- 添加的路径优先级会放到最高。
--
-- @param #string path 完整的路径。
System.pushFrontFontSearchPath = function(path)
    sys_set_string("push_front_fonts_path", path);
end

---
-- 获得版本号.
--
-- @return #string 版本号。
System.getVersion = function()
    return sys_get_string("version")
end


---
-- 是否启用模板测试.
-- 用到模板相关的功能需要先开启模板测试，否则无效。
--
-- @param #boolean state 是否打开模板测试，true为打开，false为关闭.
System.setStencilState = function (state)
    Window.instance().root.fbo.need_stencil = state
end

System.startTextureAutoCleanup = function (multiply)
    local totalMemory = Application.instance():getTotalMemory()
    local threshold = totalMemory * (multiply or (1 / 4))
    if System.getPlatform() == kPlatformAndroid and threshold > 0 then
        local _paused = false
        MemoryMonitor.instance():add_listener(threshold, function(size)
            if not _paused then
                _paused = true
                TextureCache.instance():clean_unused()
                Clock.instance():schedule_once(function()
                    if MemoryMonitor.instance().size > threshold then
                        TextureCache.instance():clean_unused()
                    end
                    _paused = false
                end, 5)
            end
        end)
    end
end

System.onInit = function ()
    collectgarbage("setpause", 100);
    collectgarbage("setstepmul", 5000);
    System.startTextureAutoCleanup();
    Label.config(System.getLayoutScale(), 24, false)
    Window.instance().root.fbo.need_stencil = true
end

local kDefaultResSearchPath = {
    sys_get_string("storage_update_root"),
    System.getStorageOuterRoot(),
    System.getStorageUserPath(),
    System.getStorageAppRoot(),
}

System.getResFullPath = function (filename)
    for _,path in ipairs(kDefaultResSearchPath) do
        if os.isexist(path .. filename) ~= false then
            return path .. filename
        end
    end
    return nil
end
end
        

package.preload[ "core.system" ] = function( ... )
    return require('core/system')
end
            

package.preload[ "core/systemEvent" ] = function( ... )

--------------------------------------------------------------------------------
-- 一些系统底层事件的调用.
-- **这里的方法都不应该被手动调用。**
--
-- @module core.systemEvent
-- @return #nil 
-- @usage require("core/systemEvent")

require 'core.eventDispatcher'


-- systemEvnet.lua
-- Author: Vicent.Gong
-- Date: 2013-01-25
-- Last modification : 2012-05-30
-- Description: Default engine event listener

-- raw touch 

---
-- 收到屏幕触摸事件，并派发触摸事件的消息.
--
-- @param #number finger_action 手指事件类型 取值:([```kFingerDown```](core.constants.html#kFingerDown)/[```kFingerMove```](core.constants.html#kFingerMove)/[```kFingerUp```](core.constants.html#kFingerUp)/[```kFingerCancel```](core.constants.html#kFingerCancel))
-- @param #number x 屏幕上的绝对x坐标。
-- @param #number y 屏幕上的绝对y坐标。 
-- @param #number drawing_id 手指触摸到的drawing对象的id。
function event_touch_raw(finger_action, x, y, drawing_id)
	EventDispatcher.getInstance():dispatch(Event.RawTouch,finger_action,x,y,drawing_id);
end

-- native call callback function

---
-- 收到native层(android/win32/ios等)的调用，并派发相应的消息.
-- 在native层使用`call_native("event_call")`会调用到这个方法。
function event_call()
	EventDispatcher.getInstance():dispatch(Event.Call);
end

---
-- 收到android上按返回键的事件，并派发此消息.
function event_backpressed()
	EventDispatcher.getInstance():dispatch(Event.Back);
end

---
-- 收到win32上的键盘按键事件，并派发此消息。
--
-- @param #number key 键盘码。
function event_win_keydown(key)
	EventDispatcher.getInstance():dispatch(Event.KeyDown,key);
end

-- application go to background

---
-- 收到应用程序进入后台的事件，并派发此消息.
-- 详见：@{core.system#System.setEventPauseEnable}。
function event_pause()
	EventDispatcher.getInstance():dispatch(Event.Pause);
end

-- application come to foreground

---
-- 收到应用程序进入前台的事件，并派发此消息.
-- 参见@{core.system#System.setEventResumeEnable}。
-- 留意：第一次启动程序时此事件并不会被触发。
function event_resume()
	EventDispatcher.getInstance():dispatch(Event.Resume); 
end       

-- system timer time up callback

---
-- 
-- 该方法是一个基于java层定时器的回调，
function event_system_timer()
	local timerId = dict_get_int("SystemTimer", "Id", -1);
	if timerId == -1 then
		return
	end
	
	EventDispatcher.getInstance():dispatch(Event.Timeout,timerId);
end
end
        

package.preload[ "core.systemEvent" ] = function( ... )
    return require('core/systemEvent')
end
            

package.preload[ "core/version" ] = function( ... )

--返回core版本号
return '3.0(c5f1841dbd1fada26ddd759f495247496c435400)'

end
        

package.preload[ "core.version" ] = function( ... )
    return require('core/version')
end
            

package.preload[ "core/zip" ] = function( ... )
-- zip.lua
-- Author: JoyFang
-- Date: 2015-12-23


--------------------------------------------------------------------------------
-- 这个模块提供了解压缩```.zip```文件（夹）的方法。
--
-- @module core.zip
-- @usage local Zip= require 'core.zip' 

local M={}

---
--覆盖解压.zip文件.    
--文件名（路径）不支持中文. 
--@param #string zipFileName 需解压的zip文件，绝对路径.
--@param #string extractDir 解压的目标目录，绝对路径.**这个目录必须是存在的，引擎不会去创建。**
--@return #boolean true或false.  
--若文件路径有误或解压失败，则返回false；若解压成功，返回true.
M.unzipWholeFile =  function (zipFileName, extractDir)
    if zipFileName==nil or string.len(zipFileName)<1 then
     return false
    end
     if extractDir==nil or string.len(extractDir)<1 then
     return false
    end
   
    return  unzipWholeFile(zipFileName, extractDir,nil)==1
end


---
--覆盖解压.zip文件，支持解压zip的特定目录.
--文件名（路径）不支持中文. 
--@param #string zipFileName 需解压的zip文件.
--@param #string extractDirInZip 相对于zip文件某一级目录.若为空字符串则表示根目录.
--@param #string extractDir 解压的目标目录.
--@return #boolean true或false.  
--若文件路径有误或解压失败，则返回false；若解压成功，返回true.
M.unzipDir = function (zipFileName,extractDirInZip,extractDir)
    if zipFileName==nil or string.len(zipFileName)<1 then
     return false
    end

  if extractDir==nil or string.len(extractDir)<1 then
     return false
    end

    return unzipDir(zipFileName,extractDirInZip,extractDir,nil)==1
end
return M


end
        

package.preload[ "core.zip" ] = function( ... )
    return require('core/zip')
end
            
require("core.anim");
require("core.blend");
require("core.constants");
require("core.dict");
require("core.drawing");
require("core.eventDispatcher");
require("core.gameString");
require("core.global");
require("core.gzip");
require("core.md5");
require("core.object");
require("core.prop");
require("core.res");
require("core.sound");
require("core.state");
require("core.stateMachine");
require("core.system");
require("core.systemEvent");
require("core.version");
require("core.zip");