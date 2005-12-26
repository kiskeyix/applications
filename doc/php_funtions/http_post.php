<?php
    /*
     * $Revision: 1.1 $
     * $Date: 2005-12-26 20:09:39 $
     */
function PostToHost ($host, $path, $referer, $data_to_send, $targeturl)
{
        $fp = fsockopen ($host, 80);
        printf ("Wiki found...\n");
        fputs ($fp, "POST $path HTTP/1.1\r\n");
        fputs ($fp, "Host: $host\r\n");
        fputs ($fp, "Referer: $referer\r\n");
        fputs ($fp, "Content-type: application/x-www-form-urlencoded\r\n");
        fputs ($fp, "Content-length: ".strlen ($data_to_send)."\r\n");
        fputs ($fp, "Connection: close\r\n\r\n");
        fputs ($fp, $data_to_send);
        printf ("Submitted to $host<br />");
        while (!feof ($fp))
        {
                $res. = fgets ($fp, 128);
        }
        printf ("Posted to $host</br>");
        fclose ($fp);
        return $res;
}
?>
