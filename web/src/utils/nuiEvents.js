export const isEnvBrowser = () => !(window).invokeNative;

export async function fetchNui(eventName, data) {
  const options = {
    method: 'post',
    headers: {
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: JSON.stringify(data),
  };

  if (isEnvBrowser()) {
    return {
      data: [],
      meta: {
        ok: true,
        status: 200,
      },
    };
  }

  const resourceName = (window).GetParentResourceName
    ? (window).GetParentResourceName()
    : 'lb-multicharacter';

  const resp = await fetch(`https://${resourceName}/${eventName}`, options);

  const respFormatted = await resp.json();

  return respFormatted;
}
