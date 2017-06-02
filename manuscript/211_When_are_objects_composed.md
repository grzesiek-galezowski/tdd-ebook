# When are objects composed?

The quick answer to this question is: as early as possible. Now, that wasn't too helpful, was it? So here goes a clarification.

Many of the objects we use in our applications can be created and connected up-front when the application starts and can stay alive until the application finishes executing. Let's call this part the **static part** of the web.

Apart from that, there's something I'll call **dynamic part** -- the objects that are created, connected and destroyed many times during the application lifecycle. There are at least two reasons this dynamic part exists:

1. Some objects represent requests or user actions that arrive during the application runtime, are processed and then discarded. These objects cannot be created up-front, but only as early as the events they represent occur. Also, these objects do not live until the application is terminated, but are discarded as soon as the processing of a request is finished. Other objects represent e.g. items in cache that live for some time and then expire, so, again, we don't have enough information to compose these objects up-front and they often don't live as long as the application itself. Such objects come and go, making temporary connections.
1. There are objects that have life spans as long as the application has, but the nature of their connections are temporary. Consider an example where we want to encrypt our data storage for export, but depending on circumstances, we sometimes want to export it using one algorithm and sometimes using another. If so, we may sometimes invoke the encryption method like this:

  ```csharp
  database.encryptUsing(encryption1);
  ```

  and sometimes like this:

  ```csharp
  database.encryptUsing(encryption2);
   ```

  In the first case, `database` and `encryption1` are only connected temporarily, for the time it takes to perform the encryption. Still, nothing prevents these objects from being created during the application startup. The same applies to the connection of `database` and `encryption2` - this connection is temporary as well.

Given these definitions, it is perfectly possible for an object to be part of both static and dynamic part -- some of its connections may be made up-front, while others may be created later, e.g. when its reference is passed inside a message sent to another object (i.e. when it is passed as method parameter).

