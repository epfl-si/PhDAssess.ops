/**
 * An implementation of java.util.function.BiConsumer that works as
 * a Perl callback (using https://metacpan.org/dist/Java)
 */

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.ObjectOutputStream;
import java.io.Serializable;
import java.util.Base64;
import java.util.function.BiConsumer;
import com.zzo.javaserver.Callback;
import io.camunda.zeebe.util.buffer.BufferWriter;
import org.agrona.MutableDirectBuffer;
import org.agrona.ExpandableDirectByteBuffer;

public class PerlBiConsumer<T extends BufferWriter, U extends BufferWriter> implements BiConsumer<T, U> {

    Callback p;
    String format;

    public PerlBiConsumer (Callback p)
    {
        this.p = p;
        this.format = "";
    }

    public void setFormat (String format) {
        this.format = format;
    }

    static private <S extends BufferWriter> byte[] bytesOf(S obj) {
        MutableDirectBuffer buf =
            new ExpandableDirectByteBuffer(8);
        obj.write(buf, 0);
        byte[] retval = new byte[buf.capacity()];
        buf.getBytes(0, retval);
        return retval;
    }

    static private <S extends BufferWriter> String base64Of(S obj) {
        return Base64.getEncoder().encodeToString(bytesOf(obj));
    }

    public void accept(T t, U u) {
        p.eval(String.format(this.format, base64Of(t), base64Of(u)));
    }
}
