package zhb;

import java.io.File;
import java.lang.reflect.Field;

public class JavaClass {


    static int num =0;

    public static void main(String[] args) {

        getFile(new File("C:\\Users\\zhb\\AppData\\Roaming\\MetaQuotes\\Terminal\\9E1B7C64C22DC2B6AAD000B3A8AB1869\\MQL4\\Include"),"/Include/");

    }


    /**
     * 递归获取当前文件夹中的文件
     * @param f        目录中的文件
     */
    private static void getFile(File f,String path) {
        // 如果还存在子目录，继续读取子目录下的文件
        if (f.isDirectory()) {
            File[] subFiles = f.listFiles();
            for (File file : subFiles) {
                getFile(file,path);// 递归寻找指定文件
            }
            // 不存在子目录，则判断文件名是否相同
        } else {
            // 判断当前文件的名字是否和需要寻找的文件名相同
            // 输出文件名
            System.out.println(f.getAbsolutePath().replaceAll("",""));
            // 操作文件数量和路径
        }
    }

    /**
     * 操作文件数量和打印文件路径
     * @param f 当前操作的文件
     */
    private static void getData(File f) {
        num++;
        System.out.println("=====路径为：");
        System.out.println(f.getPath());
    }

}
