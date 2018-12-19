# -*- coding: utf-8 -*-
# @Author: LensarZhang
# @Date:   2018-11-28 15:10:03
# @Last Modified by:   LensarZhang
# @Last Modified time: 2018-11-28 17:01:34
import sys
import subprocess
reload(sys)
from sys import argv
sys.setdefaultencoding('utf-8')
import os


# os.system("sed -r \"s/\\x1B\\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g\"")
# os.system("grep --color=never")

# print(os.popen("find . -name \"*.lua\""))
# os.popen("ls")
# os.system("ls")
# os.popen('dir')
def check_dir(path):
    p = subprocess.Popen('find ' + path + ' -name \"*.lua\"', shell=True, stdout=subprocess.PIPE)
    out, err = p.communicate()
    flag = True
    for line in out.splitlines():
        p1 = subprocess.Popen(sys.path[0] + "/bin/luacheck " + line + " --no-color", shell=True, stdout=subprocess.PIPE)
        out1, err1 = p1.communicate()
        if out1.find("0 errors in 1 file") == -1:
            flag = False
            print(out1)
    if flag:
        print("0 error")
def check_file(path):
    p1 = subprocess.Popen(sys.path[0] + "/bin/luacheck " + path + " --no-color", shell=True, stdout=subprocess.PIPE)
    out1, err1 = p1.communicate()
    print(out1)
if __name__ == "__main__":
    length = len(argv)
    if length == 2:
        if os.path.exists(argv[1]):
            if os.path.isdir(argv[1]):
                check_dir(argv[1])
            elif os.path.isfile(argv[1]):
                check_file(argv[1])
            else:
                print("参数错误：路径需要是文件路径或目录")
        else:
            print("参数错误：路径不存在")
    else:
        print("缺少参数：待check路径或参数冗余")